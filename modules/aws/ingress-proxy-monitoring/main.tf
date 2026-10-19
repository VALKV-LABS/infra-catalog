# Alarms for the ingress-proxy tier's config source, built on CloudWatch Logs
# metric filters.
#
# Why logs and not metrics: the proxy exports Prometheus text on its mgmt port and
# NOTHING scrapes it — there is no Prometheus server, no CloudWatch agent on these
# hosts, and no PutMetricData caller. Container logs, by contrast, already reach
# CloudWatch Logs through Docker's awslogs driver, and the instance role already
# carries logs:PutLogEvents (infra-catalog/modules/aws/compute-instances). So this
# needs no agent, no gold-AMI rebuild and no new IAM — it reads a line the proxy
# already writes.
#
# The tradeoff is that a metric filter can only count matching lines. It cannot do
# arithmetic, and it cannot turn a cumulative counter into a rate. That is why the
# proxy decides its own state and emits it as a literal token (see
# source_health.rs's heartbeat section): the threshold lives with the code that
# already computes it from the poll interval, and CloudWatch only counts.
#
# One consequence worth stating: a rate alarm on changelog apply errors is NOT
# possible this way. The heartbeat reports a cumulative apply_errors count for
# whoever reads the line, and that is all. See multi-region-plan.md Phase 0.

locals {
  # One log group for the whole regional tier, with one stream per node, rather
  # than the per-instance group the rest of the platform uses
  # (/valkv/<container>/<instance-name>). Deliberate: a metric filter attaches to
  # exactly ONE log group, so per-instance groups would mean one filter per node,
  # kept in sync with instance ids by hand — and an instance replacement would
  # silently leave the new node uncovered. Group-per-tier means one filter covers
  # every node including replacements, and `docker logs` on the box is unaffected.
  log_group_name = "/valkv/ingress-proxy/${var.region_label}"

  namespace = "valkv/ingress"

  alarm_actions = var.monitoring_enabled ? [aws_sns_topic.alerts[0].arn] : []

  # Matches the tokens source_health.rs emits. These are an interface: the Rust
  # side has a unit test asserting the exact three strings, because a filter that
  # matches nothing produces no datapoints, and an alarm with no datapoints looks
  # exactly like a healthy fleet.
  # The gateway node (valkv-apg) logs one JSON line a minute with this message
  # and a state: ok, stale or unconverged.
  status_line = "{ $.fields.message = \"node status\" }"
}

# ── Log group ─────────────────────────────────────────────────────────────────
# Terraform-owned so retention is actually set. The compose file passes
# awslogs-create-group=false to match: a proxy deployed into a region whose
# monitoring was never applied then fails to start loudly, instead of quietly
# creating a group that keeps logs forever and that Terraform would later refuse
# to adopt.

resource "aws_cloudwatch_log_group" "proxy" {
  name              = local.log_group_name
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

# ── SNS ───────────────────────────────────────────────────────────────────────
# Same shape as krocks-redis/deploy/terraform/aws/modules/valkv-region's
# monitoring.tf rather than a second notification path.

resource "aws_sns_topic" "alerts" {
  count = var.monitoring_enabled ? 1 : 0
  name  = "valkv-${var.region_label}-ingress-alerts"
  tags  = var.tags
}

resource "aws_sns_topic_subscription" "alerts" {
  for_each = var.monitoring_enabled ? { for i, s in var.subscriptions : tostring(i) => s } : {}

  topic_arn = aws_sns_topic.alerts[0].arn
  protocol  = each.value.protocol
  endpoint  = each.value.endpoint
}

# ── Metric filters ────────────────────────────────────────────────────────────

# Every heartbeat line, whatever the state. Its ABSENCE is the signal: a proxy
# that has stopped writing these is not reporting stale or unconverged, it is not
# reporting at all.
resource "aws_cloudwatch_log_metric_filter" "heartbeat" {
  name           = "valkv-${var.region_label}-ingress-config-source-heartbeat"
  log_group_name = aws_cloudwatch_log_group.proxy.name
  pattern        = local.status_line

  metric_transformation {
    name      = "ConfigSourceHeartbeat"
    namespace = local.namespace
    value     = "1"
    # No default_value: with one, a period containing no matching lines reports 0
    # instead of nothing, and the missing-data alarm below could never fire.
    unit = "Count"
    # No dimensions. The obvious one would be Region, but this log group already
    # belongs to exactly one regional tier, so every datapoint from it is that
    # region's — a dimension would restate the group name. (It also could not be
    # extracted: dimension values use JSON-path syntax like "$.region", and these
    # lines are tracing's key=value text, not JSON.)
  }
}

resource "aws_cloudwatch_log_metric_filter" "unconverged" {
  name           = "valkv-${var.region_label}-ingress-config-source-unconverged"
  log_group_name = aws_cloudwatch_log_group.proxy.name
  pattern        = "{ $.fields.message = \"node status\" && $.fields.state = \"unconverged\" }"

  metric_transformation {
    name      = "ConfigSourceUnconverged"
    namespace = local.namespace
    value     = "1"
    unit      = "Count"
  }
}

resource "aws_cloudwatch_log_metric_filter" "stale" {
  name           = "valkv-${var.region_label}-ingress-config-source-stale"
  log_group_name = aws_cloudwatch_log_group.proxy.name
  pattern        = "{ $.fields.message = \"node status\" && $.fields.state = \"stale\" }"

  metric_transformation {
    name      = "ConfigSourceStale"
    namespace = local.namespace
    value     = "1"
    unit      = "Count"
  }
}

# ── Alarms ────────────────────────────────────────────────────────────────────

# A node with nothing to serve. This is the one genuinely per-node failure in this
# design: empty cache, so it 404s everything. /readyz already returns 503 in this
# state and the NLB holds the node out of rotation, so this alarm is about a node
# that is STUCK there, not one that is simply starting up — hence 5 minutes rather
# than one period.
resource "aws_cloudwatch_metric_alarm" "unconverged" {
  count = (var.monitoring_enabled && var.create_default_alarms) ? 1 : 0

  alarm_name        = "valkv-${var.region_label}-ingress-config-source-unconverged"
  alarm_description = <<-EOT
    An ingress-proxy node has not converged for 5 minutes: empty routing cache,
    nothing to serve, 404s everything it is sent. /readyz is 503 and the NLB is
    holding it out, so customer traffic is not hitting it — but the tier is down a
    node and a replacement is not joining.

    Look at: can the node reach the gateway control plane (APG_CONFIG_URL, the app
    tier on port 9001 over the peering link), and is its APG_NODE_TOKEN the one
    the control plane has?
  EOT

  namespace           = local.namespace
  metric_name         = "ConfigSourceUnconverged"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  evaluation_periods  = 5
  period              = 60
  statistic           = "Sum"
  # A node that is not logging "unconverged" is either fine or dead; dead is the
  # heartbeat alarm's job, not this one.
  treat_missing_data = "notBreaching"
  alarm_actions      = local.alarm_actions
  ok_actions         = local.alarm_actions
  tags               = var.tags
}

# Staleness across the tier. Deliberately NOT wired to readiness or to the load
# balancer: every node in a region reads one config source, so they go stale
# together, and draining on that would turn a control-plane outage into a total
# regional data-plane outage while each node was still serving correct routes from
# its local cache. Minutes, not the seconds a health check would use — staleness is
# tolerated by design. See multi-region-plan.md 4.4.
resource "aws_cloudwatch_metric_alarm" "stale" {
  count = (var.monitoring_enabled && var.create_default_alarms) ? 1 : 0

  alarm_name        = "valkv-${var.region_label}-ingress-config-source-stale"
  alarm_description = <<-EOT
    The ingress-proxy tier's config source has been unreachable for ~15 minutes.
    The proxies are still serving their last-known routing table, which is correct
    behaviour and must not be "fixed" by draining them.

    What is actually broken is the CONTROL plane: new stores, routes and certs are
    not reaching the data plane. Existing customer traffic is unaffected.

    Look at: is apg-admin running on the app tier, and is port 9001 reachable from
    the proxy subnet?
  EOT

  namespace           = local.namespace
  metric_name         = "ConfigSourceStale"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  evaluation_periods  = 3
  period              = 300
  statistic           = "Sum"
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
  tags                = var.tags
}

# No heartbeat at all. Catches a proxy that is wedged or gone in a way the NLB
# health check might not: the mgmt socket can still accept connections and answer
# /healthz while the background tasks are dead.
resource "aws_cloudwatch_metric_alarm" "heartbeat_missing" {
  count = (var.monitoring_enabled && var.create_default_alarms) ? 1 : 0

  alarm_name        = "valkv-${var.region_label}-ingress-config-source-no-heartbeat"
  alarm_description = <<-EOT
    No ingress-proxy in this region has logged a config-source heartbeat for 5
    minutes. Either every node is down, or their logs have stopped reaching
    CloudWatch.

    Distinguish the two before treating it as an outage: check the NLB's
    UnHealthyHostCount and whether anything else in the region is still logging. A
    broken log path presents identically to a dead fleet here, which is the cost of
    alarming over logs.
  EOT

  namespace           = local.namespace
  metric_name         = "ConfigSourceHeartbeat"
  comparison_operator = "LessThanThreshold"
  threshold           = 1
  evaluation_periods  = 5
  period              = 60
  statistic           = "Sum"
  # The whole point: no data IS the alarm condition here.
  treat_missing_data = "breaching"
  alarm_actions      = local.alarm_actions
  ok_actions         = local.alarm_actions
  tags               = var.tags
}
