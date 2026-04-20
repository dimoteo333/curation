class NotesImportGuide {
  const NotesImportGuide._();

  static const String title = 'Apple Notes 가져오기 안내';
  static const String summary =
      'Apple Notes를 직접 데이터베이스에서 읽지는 않지만, iOS 공유 시트로 큐레이터에 보내거나 `.txt` 또는 `.md` 파일로 내보낸 뒤 가져올 수 있습니다.';
  static const List<String> steps = <String>[
    'iPhone 또는 iPad에서 메모 앱을 열고 가져올 노트를 선택합니다.',
    '공유 버튼을 눌러 큐레이터 공유 확장으로 바로 보내거나, 파일 앱에 `.txt` 또는 `.md`로 저장합니다.',
    '공유 확장을 썼다면 큐레이터가 다음 실행 또는 복귀 시 자동으로 공유된 텍스트를 가져옵니다.',
    '파일로 저장했다면 큐레이터 설정에서 `내보낸 메모 파일 가져오기`를 눌러 저장한 `.txt` 또는 `.md` 파일을 선택합니다.',
    '가져온 노트는 로컬 벡터 DB에 저장되고 이후 큐레이션 문맥으로 사용됩니다.',
  ];
  static const String fallbackTip =
      '직접 파일 export가 어렵다면 메모 내용을 복사해 새 텍스트 파일로 저장한 뒤 가져와도 됩니다.';
}
