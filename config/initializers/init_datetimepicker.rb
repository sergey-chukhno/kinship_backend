ActiveAdminDatetimepicker::Base.default_datetime_picker_options = {
  format: "d/m/Y H:i",
  defaultTime: proc { Time.current.strftime("%H:00") }
}
ActiveAdminDatetimepicker::Base.format = "%d/%m/%Y %H:%M"
