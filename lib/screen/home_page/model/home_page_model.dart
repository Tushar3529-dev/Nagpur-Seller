import 'package:hyper_local_seller/service/json_parser.dart';

const String modelName = 'home_page_model';

class HomePageResponse {
  bool? success;
  String? message;
  HomePageData? data;

  HomePageResponse({this.success, this.message, this.data});

  factory HomePageResponse.fromJson(Map<String, dynamic> json) {
    return HomePageResponse(
      success: JsonParser.boolValue(json['success'] ?? false),
      message: JsonParser.string(json['message'] ?? ''),
      data: json['data'] != null
          ? HomePageData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class HomePageData {
  DashboardChart? chart;
  DashboardSummary? summary;

  HomePageData({this.chart, this.summary});

  factory HomePageData.fromJson(Map<String, dynamic> json) {
    return HomePageData(
      chart: json['chart'] != null
          ? DashboardChart.fromJson(json['chart'] as Map<String, dynamic>)
          : null,
      summary: json['summary'] != null
          ? DashboardSummary.fromJson(json['summary'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (chart != null) data['chart'] = chart!.toJson();
    if (summary != null) data['summary'] = summary!.toJson();
    return data;
  }
}

class DashboardChart {
  WeeklyChartData? weekly;
  MonthlyChartData? monthly;
  YearlyChartData? yearly;

  DashboardChart({this.weekly, this.monthly, this.yearly});

  factory DashboardChart.fromJson(Map<String, dynamic> json) {
    return DashboardChart(
      weekly: json['weekly'] != null
          ? WeeklyChartData.fromJson(json['weekly'] as Map<String, dynamic>)
          : null,
      monthly: json['monthly'] != null
          ? MonthlyChartData.fromJson(json['monthly'] as Map<String, dynamic>)
          : null,
      yearly: json['yearly'] != null
          ? YearlyChartData.fromJson(json['yearly'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (weekly != null) data['weekly'] = weekly!.toJson();
    if (monthly != null) data['monthly'] = monthly!.toJson();
    if (yearly != null) data['yearly'] = yearly!.toJson();
    return data;
  }
}

class WeeklyChartData {
  String period;
  List<WeeklyEntry>? entries;

  WeeklyChartData({
    required this.period,
    this.entries,
  });

  factory WeeklyChartData.fromJson(Map<String, dynamic> json) {
    return WeeklyChartData(
      period: JsonParser.string(json['period'] ?? 'Week'),
      entries: JsonParser.list<WeeklyEntry>(
        json['data'],
            (v) => WeeklyEntry.fromJson(v as Map<String, dynamic>),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['period'] = period;
    if (entries != null) {
      data['data'] = entries!.map((e) => e.toJson()).toList();
    }
    return data;
  }
}

class WeeklyEntry {
  String day;
  int earnings;
  int orders;

  WeeklyEntry({
    required this.day,
    required this.earnings,
    required this.orders,
  });

  factory WeeklyEntry.fromJson(Map<String, dynamic> json) {
    return WeeklyEntry(
      day: JsonParser.string(json['day'] ?? ''),
      earnings: JsonParser.intValue(json['earnings'] ?? 0),
      orders: JsonParser.intValue(json['orders'] ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['day'] = day;
    data['earnings'] = earnings;
    data['orders'] = orders;
    return data;
  }
}

class MonthlyChartData {
  String period;
  List<MonthlyEntry>? entries;

  MonthlyChartData({
    required this.period,
    this.entries,
  });

  factory MonthlyChartData.fromJson(Map<String, dynamic> json) {
    return MonthlyChartData(
      period: JsonParser.string(json['period'] ?? 'Month'),
      entries: JsonParser.list<MonthlyEntry>(
        json['data'],
            (v) => MonthlyEntry.fromJson(v as Map<String, dynamic>),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['period'] = period;
    if (entries != null) {
      data['data'] = entries!.map((e) => e.toJson()).toList();
    }
    return data;
  }
}

class MonthlyEntry {
  String week;
  double earnings;
  int orders;

  MonthlyEntry({
    required this.week,
    required this.earnings,
    required this.orders,
  });

  factory MonthlyEntry.fromJson(Map<String, dynamic> json) {
    return MonthlyEntry(
      week: JsonParser.string(json['week'] ?? ''),
      earnings: JsonParser.doubleValue(json['earnings'] ?? 0.0),
      orders: JsonParser.intValue(json['orders'] ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['week'] = week;
    data['earnings'] = earnings;
    data['orders'] = orders;
    return data;
  }
}

class YearlyChartData {
  String period;
  List<YearlyEntry>? entries;

  YearlyChartData({
    required this.period,
    this.entries,
  });

  factory YearlyChartData.fromJson(Map<String, dynamic> json) {
    return YearlyChartData(
      period: JsonParser.string(json['period'] ?? 'Year'),
      entries: JsonParser.list<YearlyEntry>(
        json['data'],
            (v) => YearlyEntry.fromJson(v as Map<String, dynamic>),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['period'] = period;
    if (entries != null) {
      data['data'] = entries!.map((e) => e.toJson()).toList();
    }
    return data;
  }
}

class YearlyEntry {
  String month;
  double earnings;
  int orders;
  int? percentage;

  YearlyEntry({
    required this.month,
    required this.earnings,
    required this.orders,
    this.percentage,
  });

  factory YearlyEntry.fromJson(Map<String, dynamic> json) {
    return YearlyEntry(
      month: JsonParser.string(json['month'] ?? ''),
      earnings: JsonParser.doubleValue(json['earnings'] ?? 0.0),
      orders: JsonParser.intValue(json['orders'] ?? 0),
      percentage: JsonParser.intValue(json['percentage']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['month'] = month;
    data['earnings'] = earnings;
    data['orders'] = orders;
    data['percentage'] = percentage;
    return data;
  }
}

class DashboardSummary {
  SummaryItem? todaysRevenue;
  SummaryItem? totalOrders;
  SummaryItem? totalProducts;
  SummaryItem? sales;

  DashboardSummary({
    this.todaysRevenue,
    this.totalOrders,
    this.totalProducts,
    this.sales,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      todaysRevenue: json['todays_revenue'] != null
          ? SummaryItem.fromJson(json['todays_revenue'] as Map<String, dynamic>)
          : null,
      totalOrders: json['total_orders'] != null
          ? SummaryItem.fromJson(json['total_orders'] as Map<String, dynamic>)
          : null,
      totalProducts: json['total_products'] != null
          ? SummaryItem.fromJson(json['total_products'] as Map<String, dynamic>)
          : null,
      sales: json['sales'] != null
          ? SummaryItem.fromJson(json['sales'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (todaysRevenue != null) data['todays_revenue'] = todaysRevenue!.toJson();
    if (totalOrders != null) data['total_orders'] = totalOrders!.toJson();
    if (totalProducts != null) data['total_products'] = totalProducts!.toJson();
    if (sales != null) data['sales'] = sales!.toJson();
    return data;
  }
}

class SummaryItem {
  String title;
  String value;
  String? message;
  int? change;

  SummaryItem({
    required this.title,
    required this.value,
    this.message,
    this.change,
  });

  factory SummaryItem.fromJson(Map<String, dynamic> json) {
    return SummaryItem(
      title: JsonParser.string(json['title'] ?? ''),
      value: JsonParser.string(json['amount'] ?? json['count'] ?? json['solds']?.toString() ?? '0'),
      message: JsonParser.string(json['message'] ?? ''),
      change: JsonParser.intValue(json['change']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['title'] = title;
    data['amount'] = value; // or 'count' / 'solds' depending on context
    data['message'] = message;
    data['change'] = change;
    return data;
  }
}