import 'google_maps_urls.dart';

/// Host-independent, immutable input for complete Markdown roadbook export.
class RoadbookSnapshot {
  const RoadbookSnapshot({
    required this.name,
    required this.startDateLabel,
    required this.plannedDays,
    required this.visibleDaysCount,
    required this.baseCurrency,
    required this.timeZone,
    required this.days,
    required this.items,
    required this.preparations,
    required this.budget,
    this.note = '',
    this.rates = const {},
  });

  final String name;
  final String startDateLabel;
  final int plannedDays;
  final int visibleDaysCount;
  final String baseCurrency;
  final String timeZone;
  final String note;
  final Map<String, String> rates;
  final List<RoadbookDay> days;
  final List<RoadbookItem> items;
  final List<RoadbookPreparation> preparations;
  final RoadbookBudget budget;
}

class RoadbookDay {
  const RoadbookDay({
    required this.number,
    required this.dateLabel,
    required this.entries,
    required this.stays,
    required this.arrivals,
  });

  final int number;
  final String dateLabel;
  final List<RoadbookTimelineEntry> entries;
  final List<RoadbookItem> stays;
  final List<RoadbookArrival> arrivals;
}

class RoadbookTimelineEntry {
  const RoadbookTimelineEntry({
    required this.item,
    required this.prefix,
    required this.time,
    required this.appointment,
  });

  final RoadbookItem item;
  final String prefix;
  final String time;
  final bool appointment;
}

class RoadbookArrival {
  const RoadbookArrival({required this.location, this.googleMapsUrl = ''});

  final String location;
  final String googleMapsUrl;
}

class RoadbookItem {
  const RoadbookItem({
    required this.id,
    required this.title,
    required this.type,
    required this.typeLabel,
    required this.day,
    required this.dayLabel,
    required this.endDay,
    required this.endDayLabel,
    required this.booking,
    required this.done,
    required this.fields,
    required this.costs,
    this.note = '',
    this.isTransport = false,
    this.isFlight = false,
  });

  final String id;
  final String title;
  final String type;
  final String typeLabel;
  final int day;
  final String dayLabel;
  final int endDay;
  final String endDayLabel;
  final String booking;
  final bool done;
  final String note;
  final bool isTransport;
  final bool isFlight;
  final Map<String, String> fields;
  final List<RoadbookCost> costs;
}

class RoadbookCost {
  const RoadbookCost({
    required this.label,
    required this.amount,
    required this.currency,
    required this.category,
  });

  final String label;
  final String amount;
  final String currency;
  final String category;
}

class RoadbookPreparation {
  const RoadbookPreparation({
    required this.name,
    required this.done,
    this.due = '',
    this.note = '',
  });

  final String name;
  final bool done;
  final String due;
  final String note;
}

class RoadbookBudget {
  const RoadbookBudget({required this.currencies, required this.unknownCount});

  final List<RoadbookCurrencyBudget> currencies;
  final int unknownCount;
}

class RoadbookCurrencyBudget {
  const RoadbookCurrencyBudget({
    required this.currency,
    required this.total,
    required this.categories,
  });

  final String currency;
  final String total;
  final List<RoadbookCategoryBudget> categories;
}

class RoadbookCategoryBudget {
  const RoadbookCategoryBudget({required this.category, required this.amount});

  final String category;
  final String amount;
}

/// Sanitizes a trip name for a single Markdown export file.
String roadbookFileName(String tripName) {
  var name = tripName
      .replaceAll(RegExp(r'[<>:"/\\|?*]'), '-')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim()
      .replaceAll(RegExp(r'^\.+|\.+$'), '');
  if (name.length > 80) name = name.substring(0, 80).trim();
  if (name.isEmpty) name = '旅行';
  return 'HowDoI-$name.md';
}

/// Renders a full, self-contained Markdown roadbook without network access.
String exportRoadbookMarkdown(RoadbookSnapshot snapshot) {
  final lines = <String>[];
  _appendTripOverview(lines, snapshot);
  lines.addAll(['', '## 逐日安排', '已填写的 Google Maps URL 会附在对应地名上；航班不生成地图链接。', '']);
  for (final day in snapshot.days) {
    _appendDaySummary(lines, day);
  }
  lines.addAll(['## 行程详情与预算明细', '']);
  if (snapshot.items.isEmpty) lines.add('暂无行程记录。');
  for (final item in snapshot.items) {
    _appendItemDetails(lines, item);
  }
  _appendPreparations(lines, snapshot.preparations);
  _appendBudget(lines, snapshot.budget);
  return '${lines.join('\n').trimRight()}\n';
}

void _appendTripOverview(List<String> lines, RoadbookSnapshot snapshot) {
  lines.addAll([
    '# ${_markdown(snapshot.name)}',
    '',
    '## 旅行信息',
    '- 出发日期：${_markdown(snapshot.startDateLabel)}',
    '- 计划天数：${snapshot.plannedDays} 天',
    '- 已安排旅行日：${snapshot.visibleDaysCount} 天',
    '- 默认预算币种：${_markdown(snapshot.baseCurrency)}',
    '- 当地时区：${_markdown(snapshot.timeZone)}',
  ]);
  if (snapshot.note.trim().isNotEmpty) {
    lines.add('- 旅行备注：${_markdown(snapshot.note)}');
  }
  if (snapshot.rates.isNotEmpty) {
    lines.add('- 已保存汇率：');
    for (final entry in snapshot.rates.entries) {
      lines.add('  - ${_markdown('${entry.key}: ${entry.value}')}');
    }
  }
}

void _appendDaySummary(List<String> lines, RoadbookDay day) {
  final heading = day.number == 0
      ? '待安排'
      : '第 ${day.number} 天${day.dateLabel.isEmpty ? '' : ' · ${day.dateLabel}'}';
  lines.add('### $heading');
  if (day.entries.isEmpty && day.stays.isEmpty) {
    lines.add('- 暂无有日期的行程节点。');
  }
  for (final entry in day.entries) {
    final time = entry.appointment ? '预约 ${entry.time}' : entry.time;
    final timeSuffix = time.isEmpty ? '' : ' · ${_markdown(time)}';
    lines.add(
      '- ${_markdown(entry.prefix)}${_linkedItemTitle(entry.item)} · '
      '${_markdown(entry.item.typeLabel)}$timeSuffix',
    );
  }
  for (final stay in day.stays) {
    final checkout = stay.endDay > 0 ? '，第 ${stay.endDay} 天退房' : '';
    lines.add(
      '- 住宿覆盖：${_linkedItemTitle(stay)} · '
      '第 ${stay.day} 天入住$checkout',
    );
  }
  for (final arrival in day.arrivals) {
    lines.add('- 到达 ${_markdownLink(arrival.location, arrival.googleMapsUrl)}');
  }
}

void _appendItemDetails(List<String> lines, RoadbookItem item) {
  lines.add('### ${_linkedItemTitle(item)}');
  lines.add('- 活动类别：${_markdown(item.type)}');
  lines.add('- 旅行日：${_markdown(item.dayLabel)}');
  if (item.endDay > item.day && item.endDay > 0) {
    lines.add('- 结束旅行日：${_markdown(item.endDayLabel)}');
  }
  lines.add('- 预订状态：${_markdown(item.booking)}');
  lines.add('- 完成状态：${item.done ? '已完成' : '未完成'}');
  if (item.note.trim().isNotEmpty) {
    lines.add('- 备注：${_markdown(item.note)}');
  }

  final fields = Map<String, String>.from(item.fields)
    ..removeWhere(
      (key, value) =>
          value.trim().isEmpty ||
          key == 'fromId' ||
          key == 'toId' ||
          key.startsWith('geo.') ||
          _retiredLocationFields.contains(key) ||
          googleMapsUrlFields.contains(key),
    );
  if (fields.isNotEmpty) {
    lines.add('- 详细信息：');
    for (final entry in fields.entries) {
      lines.add(
        '  - ${_markdown(_fieldLabel(entry.key))}：'
        '${_linkedFieldValue(item, entry.key, entry.value)}',
      );
    }
  }

  if (item.costs.isEmpty) {
    lines.add('- 预算：未填写');
  } else {
    lines.add('- 预算明细：');
    for (final cost in item.costs) {
      final amount = cost.amount.isEmpty
          ? '未估算'
          : '${cost.amount} ${cost.currency}';
      final label = cost.label.trim();
      lines.add(
        '  - ${label.isEmpty ? '费用' : _markdown(label)} · '
        '${_markdown(cost.category)} · ${_markdown(amount)}',
      );
    }
  }
  lines.add('');
}

String _linkedItemTitle(RoadbookItem item) {
  if (item.isFlight) return _markdown(item.title);
  if (item.isTransport) {
    final origin = item.fields['origin'] ?? '';
    final destination = item.fields['destination'] ?? '';
    if (origin.isNotEmpty || destination.isNotEmpty) {
      final linkedOrigin = _markdownLink(
        origin.isEmpty ? '出发地待定' : origin,
        origin.isEmpty ? '' : item.fields['originGoogleMapsUrl'] ?? '',
      );
      final linkedDestination = _markdownLink(
        destination.isEmpty ? '目的地待定' : destination,
        destination.isEmpty
            ? ''
            : item.fields['destinationGoogleMapsUrl'] ?? '',
      );
      return '$linkedOrigin → $linkedDestination';
    }
    return _markdown(item.title);
  }
  return _markdownLink(item.title, item.fields['googleMapsUrl'] ?? '');
}

String _linkedFieldValue(RoadbookItem item, String key, String value) {
  if (item.isFlight) return _markdown(value);
  if (item.isTransport && key == 'origin') {
    return _markdownLink(value, item.fields['originGoogleMapsUrl'] ?? '');
  }
  if (item.isTransport && key == 'destination') {
    return _markdownLink(value, item.fields['destinationGoogleMapsUrl'] ?? '');
  }
  return _markdown(value);
}

String _markdownLink(String label, String url) {
  final text = _markdown(label.replaceAll(RegExp(r'[\r\n]+'), ' ').trim());
  if (url.isEmpty || !isValidGoogleMapsUrl(url)) return text;
  final target = url
      .replaceAll('(', '%28')
      .replaceAll(')', '%29')
      .replaceAll('[', '%5B')
      .replaceAll(']', '%5D');
  return '[$text]($target)';
}

void _appendPreparations(
  List<String> lines,
  List<RoadbookPreparation> preparations,
) {
  lines.addAll(['', '## 预备工作', '']);
  if (preparations.isEmpty) {
    lines.add('暂无预备事项。');
    return;
  }
  for (final entry in preparations) {
    final marker = entry.done ? '[x]' : '[ ]';
    final due = entry.due.trim();
    final dueText = due.isEmpty ? '' : ' · 截止 $due';
    lines.add('- $marker ${_markdown(entry.name)}$dueText');
    if (entry.note.trim().isNotEmpty) {
      lines.add('  - 备注：${_markdown(entry.note)}');
    }
  }
}

void _appendBudget(List<String> lines, RoadbookBudget budget) {
  lines.addAll(['', '## 预算汇总（保留原币种）', '']);
  if (budget.currencies.isEmpty) {
    lines.add('暂无已估算金额。');
  } else {
    for (final currency in budget.currencies) {
      lines.add('- ${_markdown(currency.currency)} ${currency.total}');
      for (final category in currency.categories) {
        lines.add(
          '  - ${_markdown(category.category)}：'
          '${_markdown(currency.currency)} ${category.amount}',
        );
      }
    }
  }
  lines.add('- 未估算费用：${budget.unknownCount} 笔');
}

const _retiredLocationFields = {
  'city',
  'country',
  'originCity',
  'originCountry',
  'destinationCity',
  'destinationCountry',
};

String _markdown(String value) => value
    .replaceAll('\\', r'\\')
    .replaceAll('[', r'\[')
    .replaceAll(']', r'\]')
    .replaceAll('(', r'\(')
    .replaceAll(')', r'\)')
    .replaceAll('*', r'\*')
    .replaceAll('_', r'\_')
    .replaceAll('\r\n', '\n')
    .replaceAll('\r', '\n')
    .replaceAll('\n', '  \n  ');

String _fieldLabel(String key) {
  const labels = <String, String>{
    'address': '地址 / 位置',
    'origin': '起点 / 出发地',
    'destination': '终点 / 到达地',
    'startDate': '票面开始日期',
    'endDate': '票面结束日期',
    'startTime': '计划 / 出发时间',
    'endTime': '到达 / 结束时间',
    'reservationDate': '预约日期',
    'reservationTime': '预约时间',
    'startZone': '出发时区',
    'endZone': '到达时区',
    'duration': '预计时长（分钟）',
    'number': '班次 / 线路',
    'carrier': '运营方',
    'terminalFrom': '出发航站楼',
    'terminalTo': '到达航站楼',
    'gate': '登机口 / 检票口',
    'platform': '站台',
    'seat': '座位',
    'class': '席位等级',
    'baggage': '行李额度',
    'transfer': '换乘说明',
    'reference': '预订编号',
    'contact': '联系方式',
    'checkIn': '入住 / 值机时间',
    'checkOut': '退房时间',
    'roomType': '房型',
    'rooms': '房间数',
    'vehicle': '车型',
    'distance': '预计里程（公里）',
    'mode': '交通方式',
    'opening': '营业时间',
    'reservation': '预约场次',
  };
  return labels[key] ?? key;
}
