class NotesImportGuide {
  const NotesImportGuide._();

  static const String title = 'Apple Notes 직접 읽기 안내';
  static const String summary =
      'iOS의 Apple Notes는 공개 Flutter 플러그인으로 안전하게 직접 읽어 올 수 있는 경로가 없어, 텍스트 파일 export 후 파일 가져오기를 권장합니다.';
  static const List<String> steps = <String>[
    'iPhone 또는 iPad에서 메모 앱을 열고 가져올 노트를 선택합니다.',
    '공유 버튼을 눌러 텍스트를 메일, 파일, 또는 다른 앱으로 내보냅니다.',
    '가능하면 `.txt` 형태로 저장하거나, 텍스트를 복사해 새 `.txt` 파일로 정리합니다.',
    '큐레이터 설정에서 `파일 가져오기`를 눌러 저장한 `.txt` 또는 `.md` 파일을 선택합니다.',
    '가져온 노트는 로컬 벡터 DB에 저장되고 이후 큐레이션 문맥으로 사용됩니다.',
  ];
  static const String fallbackTip =
      '직접 파일 export가 어렵다면 메모 내용을 복사해 새 텍스트 파일로 저장한 뒤 가져와도 됩니다.';
}
