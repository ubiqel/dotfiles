local ls = require("luasnip")

local s = ls.snippet
local f = ls.function_node
local i = ls.insert_node

local months = {
  "января",
  "февраля",
  "марта",
  "апреля",
  "мая",
  "июня",
  "июля",
  "августа",
  "сентября",
  "октября",
  "ноября",
  "декабря",
}

-- os.date("*t").wday: 1 = Sunday
local weekdays = {
  "Воскресенье",
  "Понедельник",
  "Вторник",
  "Среда",
  "Четверг",
  "Пятница",
  "Суббота",
}

return {
  s({ trig = "daily", dscr = "Daily note template with the current date (RU)" }, {
    f(function()
      local now = os.date("*t")
      return {
        "---",
        "date: " .. os.date("%Y-%m-%d"),
        "---",
        "",
        ("# %s, %d %s, %d"):format(weekdays[now.wday], now.day, months[now.month], now.year),
        "",
        "## Как прошёл день",
        "",
        "",
      }
    end),
    i(0),
  }),
}
