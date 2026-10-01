class MockDiary {
  const MockDiary({
    required this.date,
    required this.title,
    required this.body,
  });

  final DateTime date;
  final String title;
  final String body;
}

/// 같은 날짜에는 언제나 같은 예시 일기를 반환한다.
class MockDiaryGenerator {
  const MockDiaryGenerator();

  MockDiary forDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final samples = <(String, String)>[
      (
        '조금 느리게 걸어도 괜찮은 날',
        '아침 공기가 유난히 맑았다. 바쁜 일정 사이에 잠깐 걸으며 마음을 정리했다. 작은 장면들이 모여 오늘을 만들었다.',
      ),
      (
        '마음에 남은 작은 순간',
        '오랜만에 편안한 대화를 나눴다. 특별한 일은 없었지만 함께 웃었던 시간이 오래 기억에 남을 것 같다.',
      ),
      ('오늘도 나답게 보낸 하루', '해야 할 일을 하나씩 마쳤다. 잠시 쉬어 가는 시간에도 나를 돌볼 수 있어서 좋았다.'),
    ];
    final sample = samples[normalized.day % samples.length];
    return MockDiary(date: normalized, title: sample.$1, body: sample.$2);
  }
}
