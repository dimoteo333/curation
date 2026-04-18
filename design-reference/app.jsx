// Main app — holds navigation state and Tweaks
// Three phones side by side showing the full flow: Home → Ask → Answer (+memory sheet)

const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "mood": "cream"
}/*EDITMODE-END*/;

const MOODS = [
  { id: 'cream', label: '크림 + 테라코타', swatch: ['#F5EDE0', '#C87456', '#B89368'] },
  { id: 'peach', label: '피치 + 로즈',     swatch: ['#FBEDE6', '#D88172', '#C29A8A'] },
  { id: 'beige', label: '베이지 + 오커',    swatch: ['#F2E9D8', '#B8894A', '#A87E3F'] },
  { id: 'dusty', label: '더스티 핑크 + 세이지', swatch: ['#F4E8E6', '#C68A93', '#96A78A'] },
];

function DevicePanel({ label, sub, children }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
      <IOSDevice width={402} height={874}>
        <div style={{ width: '100%', height: '100%' }} className="paper">{children}</div>
      </IOSDevice>
      <div className="frame-label">
        {label}
        {sub && <small>{sub}</small>}
      </div>
    </div>
  );
}

function TweaksPanel({ mood, setMood, visible }) {
  if (!visible) return null;
  return (
    <div className="tweaks">
      <div className="tweaks-title">팔레트 무드</div>
      <div className="swatch-row">
        {MOODS.map(m => (
          <div key={m.id}
            onClick={() => setMood(m.id)}
            className={'swatch' + (mood === m.id ? ' sel' : '')}
            title={m.label}
            style={{
              background: `linear-gradient(135deg, ${m.swatch[0]} 33%, ${m.swatch[1]} 33%, ${m.swatch[1]} 66%, ${m.swatch[2]} 66%)`,
            }}
          />
        ))}
      </div>
      <div className="swatch-label">
        {MOODS.find(m => m.id === mood)?.label}
      </div>
    </div>
  );
}

function App() {
  const [mood, setMoodRaw] = React.useState(TWEAK_DEFAULTS.mood || 'cream');
  const [tweaksOn, setTweaksOn] = React.useState(false);

  // per-device screen state
  // Device A: Home (interactive, can navigate to Ask/Answer)
  // Device B: Ask state
  // Device C: Answer + memory sheet
  const [aScreen, setAScreen] = React.useState('home'); // home | ask | answer
  const [aQuery, setAQuery] = React.useState('');
  const [aSheet, setASheet] = React.useState(null);

  const [cSheet, setCSheet] = React.useState(null);

  const setMood = (m) => {
    setMoodRaw(m);
    document.documentElement.dataset.mood = m === 'cream' ? '' : m;
    try {
      window.parent.postMessage({ type: '__edit_mode_set_keys', edits: { mood: m } }, '*');
    } catch (e) {}
  };

  React.useEffect(() => {
    document.documentElement.dataset.mood = mood === 'cream' ? '' : mood;
  }, [mood]);

  // Edit-mode wiring
  React.useEffect(() => {
    const handler = (ev) => {
      const d = ev.data;
      if (!d || !d.type) return;
      if (d.type === '__activate_edit_mode') setTweaksOn(true);
      if (d.type === '__deactivate_edit_mode') setTweaksOn(false);
    };
    window.addEventListener('message', handler);
    try { window.parent.postMessage({ type: '__edit_mode_available' }, '*'); } catch (e) {}
    return () => window.removeEventListener('message', handler);
  }, []);

  // Device A handlers
  const aGoAsk = () => { setAScreen('ask'); };
  const aGoHome = () => { setAScreen('home'); };
  const aSubmit = (q) => { setAQuery(q); setAScreen('answer'); };
  const aOpenMem = (id) => setASheet(id);
  const aCloseMem = () => setASheet(null);

  return (
    <div className="stage">
      <div style={{
        textAlign: 'center', color: '#F5EDE0', fontFamily: 'var(--serif)',
        marginBottom: 8,
      }}>
        <div style={{
          fontSize: 11, letterSpacing: '0.2em', textTransform: 'uppercase',
          opacity: 0.5, marginBottom: 6, fontFamily: 'var(--sans)', fontWeight: 500,
        }}>Life Curator · iOS prototype</div>
        <div style={{ fontSize: 34, fontWeight: 500, letterSpacing: '-0.02em' }}>
          큐레이터 <span style={{ opacity: 0.45, fontSize: 20, fontStyle: 'italic' }}>— 내 인생의 맥락 검색</span>
        </div>
        <div style={{
          fontSize: 13, opacity: 0.5, marginTop: 8, fontFamily: 'var(--sans)',
          fontWeight: 400, maxWidth: 600, marginLeft: 'auto', marginRight: 'auto',
          textWrap: 'pretty',
        }}>
          따뜻한 종이와 테라코타의 색감. 한국어 UI · 기기 안에서만 처리되는 개인 RAG.
        </div>
      </div>

      {/* Flow row — 3 devices */}
      <div style={{
        display: 'flex', gap: 44, alignItems: 'flex-start',
        flexWrap: 'wrap', justifyContent: 'center',
      }}>
        <DevicePanel label="01 · 오늘" sub="Home / Today — live: 탭하여 질문 시작">
          <div style={{ height: '100%', position: 'relative' }}>
            {aScreen === 'home' && (
              <HomeScreen onAsk={aGoAsk} onOpenMemory={aOpenMem} onNav={() => {}} />
            )}
            {aScreen === 'ask' && (
              <AskScreen onSubmit={aSubmit} onBack={aGoHome} onNav={() => {}} />
            )}
            {aScreen === 'answer' && (
              <AnswerScreen query={aQuery} onBack={() => setAScreen('home')} onOpenMemory={aOpenMem} streamingDone={false} />
            )}
            {aSheet && <MemorySheet memoryId={aSheet} onClose={aCloseMem} />}
          </div>
        </DevicePanel>

        <DevicePanel label="02 · 질문하기" sub="Ask screen — 샘플을 탭하여 채워넣기">
          <AskScreen
            onSubmit={() => {}}
            onBack={() => {}}
            onNav={() => {}}
          />
        </DevicePanel>

        <DevicePanel label="03 · 답변" sub="Essay / letter — 숫자 [1~4]를 탭하여 기록 열기">
          <div style={{ height: '100%', position: 'relative' }}>
            <AnswerScreen
              query="나 요즘 왜 이렇게 무기력하지?"
              onBack={() => {}}
              onOpenMemory={(id) => setCSheet(id)}
              streamingDone={true}
            />
            {cSheet && <MemorySheet memoryId={cSheet} onClose={() => setCSheet(null)} />}
          </div>
        </DevicePanel>
      </div>

      {/* Hint strip */}
      <div style={{
        marginTop: 16, padding: '14px 22px',
        background: 'rgba(245, 237, 224, 0.08)',
        border: '1px solid rgba(245, 237, 224, 0.12)',
        borderRadius: 14,
        color: 'rgba(245, 237, 224, 0.8)',
        fontFamily: 'var(--sans)', fontSize: 13,
        letterSpacing: '-0.01em',
        display: 'flex', alignItems: 'center', gap: 18, flexWrap: 'wrap',
        justifyContent: 'center',
        maxWidth: 900,
      }}>
        <span style={{ opacity: 0.6, fontSize: 11, letterSpacing: '0.08em', textTransform: 'uppercase' }}>
          TRY
        </span>
        <span>① 첫 번째 폰에서 <b style={{ color: '#E8B8A4' }}>오늘의 질문</b> 카드를 탭</span>
        <span style={{ opacity: 0.3 }}>·</span>
        <span>② 질문을 입력하면 답변으로 이동</span>
        <span style={{ opacity: 0.3 }}>·</span>
        <span>③ 세 번째 폰에서 <b style={{ color: '#E8B8A4' }}>참조 번호</b>를 탭하여 기록 열기</span>
      </div>

      <TweaksPanel mood={mood} setMood={setMood} visible={tweaksOn} />
    </div>
  );
}

window.App = App;
