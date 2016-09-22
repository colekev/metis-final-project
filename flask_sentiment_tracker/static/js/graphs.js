queue()
  .defer(d3.json, "/player-tweets/all")
  // .defer(d3.json, "static/geojson/us-states.json")
  .await(makeGraphs);

function makeGraphs(error, projectsJson) {
    //Clean projectsJson data
    var playertweetsProjects = projectsJson;
    var dateFormat = d3.time.format("%Y-%m-%d");

    playertweetsProjects.forEach(function(d) {
        d["date"] = dateFormat.parse(d["date"]);
        d["player"] = d['player'];
        d["polarity"] = +d["polarity"];
        d["Practicing Well"] = +d["Practicing Well"];
        d["Injured"] = +d["Injured"];
        d["Veteran"] = +d["Veteran"];
        d["Sleeper"] = +d["Sleeper"];
    });

    //Create a Crossfilter instance
    var ndx = crossfilter(playertweetsProjects);

    //Define Dimensions
    var dateDim = ndx.dimension(function(d) { return d["date"]; });
    var polarityDim = ndx.dimension(function(d) { return d["polarity"]; });
    var playerDim = ndx.dimension(function(d) { return d["player"]; });
    var yearDim = ndx.dimension(function(d) { return d["year"]; });
    var topicDim = ndx.dimension(function (d) {
                var prac_well = d["Practicing Well"];
                var injured = d["Injured"];
                var veteran = d["Veteran"];
                var sleeper = d["Sleeper"];
                if (prac_well > injured && prac_well > veteran && prac_well > sleeper)
                    return "Practicing Well";
                else if (injured > prac_well && injured > veteran && injured > sleeper)
                    return "Injured";
                else if (veteran > injured && veteran > prac_well && veteran > sleeper)
                    return "Veteran";
                else
                    return "Sleeper";
            });

    //Calculate metrics
    var tweetsByDate = dateDim.group();
    var polarityByDate = dateDim.group().reduceSum(function(d) {
      return d["polarity"]; });
    var polarityByPlayer = playerDim.group().reduceSum(function(d) {
      return d["polarity"]; });
    var tweetsByPlayer = playerDim.group();
    var tweetsByYear = yearDim.group();
    var polarityByYear = yearDim.group().reduceSum(function(d) {
      return d['polarity']; });
    var topicGroup = topicDim.group();

    //Define values (to be used in charts)
    var minDate = dateDim.bottom(1)[0]["date"];
    var maxDate = dateDim.top(1)[0]["date"];

      //Charts
    var timeChart = dc.barChart("#time-chart");
    var yearChart = dc.rowChart("#year-chart");
    var playerChart = dc.rowChart("#player-chart");
    var topicChart = dc.pieChart("#topic-chart");

    timeChart
        .width(1200)
        .height(160)
        .margins({top: 10, right: 15, bottom: 30, left: 50})
        .dimension(dateDim)
        .group(polarityByDate)
        .transitionDuration(500)
        .x(d3.time.scale().domain([minDate, maxDate]))
        .elasticY(true)
        .yAxisLabel("Polarity")
        .yAxis().ticks(4);

    yearChart
        .width(600)
        .height(400)
        .dimension(yearDim)
        .group(polarityByYear)
        .xAxis().ticks(4);

    playerChart
        .width(600)
        .height(2000)
        .dimension(playerDim)
        .group(polarityByPlayer)
        .xAxis().ticks(4);

    topicChart
        .width(400)
        .height(500)
        .radius(200)
        .innerRadius(75)
        .dimension(topicDim)
        .group(topicGroup);

  dc.renderAll();

};
