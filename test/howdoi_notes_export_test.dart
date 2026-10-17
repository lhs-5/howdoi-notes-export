import 'package:howdoi_notes_export/howdoi_notes_export.dart';
import 'package:test/test.dart';

void main() {
  group('Google Maps URL rules', () {
    test(
      'returns one place field and two transport fields, never flight fields',
      () {
        expect(
          googleMapsUrlFieldsFor(
            isTransport: false,
            isFlight: false,
          ).map((field) => field.key),
          ['googleMapsUrl'],
        );
        expect(
          googleMapsUrlFieldsFor(
            isTransport: true,
            isFlight: false,
          ).map((field) => field.key),
          ['originGoogleMapsUrl', 'destinationGoogleMapsUrl'],
        );
        expect(
          googleMapsUrlFieldsFor(isTransport: true, isFlight: true),
          isEmpty,
        );
        expect(
          googleMapsUrlFieldsFor(isTransport: false, isFlight: true),
          isEmpty,
        );
      },
    );

    test('accepts HTTPS URLs only and normalizes stale flight values', () {
      expect(isValidGoogleMapsUrl('https://maps.app.goo.gl/a?x=1&y=2'), isTrue);
      expect(isValidGoogleMapsUrl('http://maps.google.com/maps'), isFalse);
      expect(isValidGoogleMapsUrl('https://maps.app.goo.gl/a b'), isFalse);
      expect(isValidGoogleMapsUrl(' https://maps.app.goo.gl/a'), isFalse);
      expect(
        isValidGoogleMapsUrl('https://user:pass@maps.google.com/a'),
        isFalse,
      );
      expect(
        normalizeGoogleMapsUrlFields(
          isFlight: true,
          fields: {
            'origin': '上海',
            'originGoogleMapsUrl': 'https://maps.app.goo.gl/a',
          },
        ),
        {'origin': '上海'},
      );
      expect(
        () => validateGoogleMapsUrlFields(
          isFlight: false,
          fields: {'googleMapsUrl': 'http://example.com'},
        ),
        throwsFormatException,
      );
      expect(
        () => validateGoogleMapsUrlFields(
          isFlight: true,
          fields: {'googleMapsUrl': 'https://maps.app.goo.gl/a'},
        ),
        throwsFormatException,
      );
    });
  });

  test('renders full notes export and links only supported place names', () {
    const place = RoadbookItem(
      id: 'place',
      title: '札幌塔',
      type: '游览',
      typeLabel: '游览/活动',
      day: 1,
      dayLabel: '2026-10-10 · 第 1 天',
      endDay: 0,
      endDayLabel: '待安排',
      booking: '不适用',
      done: false,
      note: '确认开放时间',
      fields: {
        'address': '大通西一丁目',
        'googleMapsUrl': 'https://maps.app.goo.gl/spot_(1)?entry=ttu&x=2',
        'city': '札幌市',
        'geo.place.lat': '43.0618',
        'startTime': '09:30',
      },
      costs: [
        RoadbookCost(
          label: '展望台门票',
          amount: '1200',
          currency: 'JPY',
          category: '门票/活动',
        ),
      ],
    );
    const transit = RoadbookItem(
      id: 'train',
      title: '新千岁机场 → 札幌站',
      type: '铁路',
      typeLabel: '铁路',
      day: 1,
      dayLabel: '2026-10-10 · 第 1 天',
      endDay: 0,
      endDayLabel: '待安排',
      booking: '已预订',
      done: false,
      isTransport: true,
      fields: {
        'origin': '新千岁机场',
        'destination': '札幌站',
        'originGoogleMapsUrl': 'https://maps.app.goo.gl/from',
        'destinationGoogleMapsUrl': 'https://maps.app.goo.gl/to',
        'number': '快速机场号',
      },
      costs: [],
    );
    const flight = RoadbookItem(
      id: 'flight',
      title: '上海浦东 → 东京羽田',
      type: '航班',
      typeLabel: '航班',
      day: 1,
      dayLabel: '2026-10-10 · 第 1 天',
      endDay: 0,
      endDayLabel: '待安排',
      booking: '已预订',
      done: false,
      isTransport: true,
      isFlight: true,
      fields: {
        'origin': '上海浦东',
        'destination': '东京羽田',
        'originGoogleMapsUrl': 'https://maps.app.goo.gl/flight-from',
        'destinationGoogleMapsUrl': 'https://maps.app.goo.gl/flight-to',
      },
      costs: [],
    );
    final snapshot = RoadbookSnapshot(
      name: '札幌旅行',
      startDateLabel: '2026-10-10',
      plannedDays: 3,
      visibleDaysCount: 1,
      baseCurrency: 'CNY',
      timeZone: 'Asia/Tokyo',
      note: '旅行级备注',
      rates: {'JPY': '0.05'},
      days: [
        const RoadbookDay(
          number: 1,
          dateLabel: '2026-10-10',
          entries: [
            RoadbookTimelineEntry(
              item: place,
              prefix: '',
              time: '09:30',
              appointment: false,
            ),
            RoadbookTimelineEntry(
              item: transit,
              prefix: '',
              time: '',
              appointment: false,
            ),
            RoadbookTimelineEntry(
              item: flight,
              prefix: '',
              time: '',
              appointment: false,
            ),
          ],
          stays: [],
          arrivals: [
            RoadbookArrival(
              location: '札幌站',
              googleMapsUrl: 'https://maps.app.goo.gl/to',
            ),
          ],
        ),
      ],
      items: [place, transit, flight],
      preparations: [
        RoadbookPreparation(
          name: '准备交通卡',
          done: true,
          due: '2026-10-09',
          note: '到机场后办理',
        ),
      ],
      budget: const RoadbookBudget(
        currencies: [
          RoadbookCurrencyBudget(
            currency: 'JPY',
            total: '1200',
            categories: [
              RoadbookCategoryBudget(category: '门票/活动', amount: '1200'),
            ],
          ),
        ],
        unknownCount: 0,
      ),
    );

    final markdown = exportRoadbookMarkdown(snapshot);
    expect(markdown, contains('# 札幌旅行'));
    expect(
      markdown,
      contains('[札幌塔](https://maps.app.goo.gl/spot_%281%29?entry=ttu&x=2)'),
    );
    expect(markdown, contains('[新千岁机场](https://maps.app.goo.gl/from)'));
    expect(markdown, contains('[札幌站](https://maps.app.goo.gl/to)'));
    expect(markdown, contains('上海浦东 → 东京羽田'));
    expect(markdown, isNot(contains('flight-from')));
    expect(markdown, isNot(contains('札幌市')));
    expect(markdown, isNot(contains('43.0618')));
    expect(markdown, contains('旅行级备注'));
    expect(markdown, contains('准备交通卡'));
    expect(markdown, contains('到机场后办理'));
    expect(markdown, contains('展望台门票'));
    expect(markdown, contains('JPY 1200'));
    expect(markdown, endsWith('\n'));
  });

  test('leaves empty or invalid URLs as plain text and escapes labels', () {
    const item = RoadbookItem(
      id: 'bad',
      title: 'A [place] (north)',
      type: '其他',
      typeLabel: '其他',
      day: 0,
      dayLabel: '待安排',
      endDay: 0,
      endDayLabel: '待安排',
      booking: '不适用',
      done: false,
      fields: {'googleMapsUrl': 'javascript:alert(1)'},
      costs: [],
    );
    final markdown = exportRoadbookMarkdown(
      const RoadbookSnapshot(
        name: '测试',
        startDateLabel: '未设置',
        plannedDays: 1,
        visibleDaysCount: 0,
        baseCurrency: 'CNY',
        timeZone: 'Asia/Shanghai',
        days: [],
        items: [item],
        preparations: [],
        budget: RoadbookBudget(currencies: [], unknownCount: 0),
      ),
    );
    expect(markdown, contains(r'A \[place\] \(north\)'));
    expect(markdown, isNot(contains('javascript:')));

    const noUrl = RoadbookItem(
      id: 'empty',
      title: 'Empty URL place',
      type: '其他',
      typeLabel: '其他',
      day: 0,
      dayLabel: '待安排',
      endDay: 0,
      endDayLabel: '待安排',
      booking: '不适用',
      done: false,
      fields: {'googleMapsUrl': ''},
      costs: [],
    );
    final emptyUrlMarkdown = exportRoadbookMarkdown(
      const RoadbookSnapshot(
        name: '测试',
        startDateLabel: '未设置',
        plannedDays: 1,
        visibleDaysCount: 0,
        baseCurrency: 'CNY',
        timeZone: 'Asia/Shanghai',
        days: [],
        items: [noUrl],
        preparations: [],
        budget: RoadbookBudget(currencies: [], unknownCount: 0),
      ),
    );
    expect(emptyUrlMarkdown, contains('### Empty URL place'));
    expect(emptyUrlMarkdown, isNot(contains('[Empty URL place](')));
  });

  test('creates a safe Markdown file name', () {
    expect(roadbookFileName('札幌/东京'), 'HowDoI-札幌-东京.md');
    expect(roadbookFileName('...'), 'HowDoI-旅行.md');
  });
}
