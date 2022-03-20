# cmg_time

A time tracker using 0-1000 time units over 24 hours.

Developed to learn some Flutter/Dart

Planned features:

* utilizes an alternative time system described by [Devine Lu Linvega/HundredRabbits](https://100r.co/) in [Future of Coding podcast episode titled "Making Your Own Tools"](https://futureofcoding.org/episodes/044)
    * 0-1000 ticks representing a 24 hours day
    * Characters from a-z representing bi-week index of year (26 bi-weeks)
    * 0-13 number representing index of day of the bi-week
    * Example: 6:29PM Mar 20 = 770-E11
* quick alarm feature allowing setting N alarms by offset (so 100 ticks from now instead of a specific time)


Here's a javascript function that converts realtime to ticks:

```js
  // Returns the ISO week of the date.
  Date.prototype.getWeek = function () {
    var date = new Date(this.getTime());
    date.setHours(0, 0, 0, 0);
    // Thursday in current week decides the year.
    date.setDate(date.getDate() + 3 - (date.getDay() + 6) % 7);
    // January 4 is always in week 1.
    var week1 = new Date(date.getFullYear(), 0, 4);
    // Adjust to Thursday in week 1 and count number of weeks from date to week1.
    return 1 + Math.round(((date.getTime() - week1.getTime()) / 86400000
      - 3 + (week1.getDay() + 6) % 7) / 7);
  }

  function currentTime() {
    // CMG-TIME: based on 100rabbits alternative time system
    var date = new Date();
    var hour = date.getHours();
    var min = date.getMinutes();
    var sec = date.getSeconds();

    var allseconds = 24 * 60 * 60;
    var curseconds = (hour * 3600) + (min * 60) + sec;
    var secsbetweenticks = allseconds / 1000;
    var cursubticks = Math.floor(((curseconds % secsbetweenticks) / secsbetweenticks) * 1000);
    var cmgticks = Math.floor((curseconds / allseconds) * 1000);

    var weekofyear = date.getWeek();
    var cmgdate = String.fromCharCode(Math.floor(weekofyear / 2) + 64) + Math.floor(weekofyear % 14).toString()

    var presentation = cmgticks.toString() + "-" + cmgdate;

    document.getElementById("cmg-time").innerText = presentation;
    document.getElementById("cmg-subticks").innerText = cursubticks;
    var t = setTimeout(function () { currentTime() }, 1000);
  }

  function updateTime(k) {
    if (k < 10) {
      return "0" + k;
    }
    else {
      return k;
    }
  }

  currentTime();
```