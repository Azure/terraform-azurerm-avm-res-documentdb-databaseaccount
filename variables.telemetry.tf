variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
  Defaults to `true`. This variable controls whether or not telemetry is enabled for the module.
  For more information see https://aka.ms/avm/telemetryinfo.
  If it is set to false, then no telemetry will be collected.
  DESCRIPTION
  nullable    = false
}
