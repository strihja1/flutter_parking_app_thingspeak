class SensorData {
  final List<Feed> feeds;

  SensorData({this.feeds});

  factory SensorData.fromJson(Map<String, dynamic> json) {
    var list = json["feeds"] as List;
    List<Feed> feedList = list.map((e) => Feed.fromJson(e)).toList();
    return SensorData(
      feeds: feedList
    );
  }
}

class Feed {
  final String date;
  final String distance;

  Feed({this.date, this.distance});

  factory Feed.fromJson(Map<String, dynamic> json) {
    return Feed(
      date: json['created_at'],
      distance:json['field1'],
    );
  }
}

