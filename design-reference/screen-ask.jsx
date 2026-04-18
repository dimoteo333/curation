// AskScreen — question input with typing / suggestions / voice option
function AskScreen({ onSubmit, onBack, onNav }) {
  const [query, setQuery] = React.useState('');
  const [focused, setFocused] = React.useState(false);
  const inputRef = React.useRef(null);

  React.useEffect(() => {
    // auto-focus feel
    const t = setTimeout(() => { setFocused(true); inputRef.current && inputRef.current.focus(); }, 120);
    return () => clearTimeout(t);
  }, []);

  const submit = (text) => {
    const q = (text !== undefined ? text : query).trim();
    if (!q) return;
    onSubmit(q);
  };

  const samples = [
    { cat: '감정', q: '나 요즘 왜 이렇게 무기력하지?' },
    { cat: '회상', q: '3년 전 봄에 뭐 하면서 즐거웠지?' },
    { cat: '패턴', q: '이직 후에 늘 이런 기분이 드나?' },
    { cat: '루틴', q: '책 읽기 가장 잘 지켜진 달이 언제였지?' },
  ];

  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', position: 'relative' }}>
      <div className="paper-grain" />
      <div style={{ height: 54 }} />

      {/* Header */}
      <div style={{
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        padding: '10px 16px 4px', position: 'relative', zIndex: 5,
      }}>
        <div
          onClick={onBack}
          style={{
            width: 36, height: 36, borderRadius: '50%',
            background: 'rgba(255,255,255,0.65)',
            border: '0.5px solid var(--line)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            cursor: 'pointer',
          }}>
          <svg width="12" height="12" viewBox="0 0 12 12" fill="none">
            <path d="M8 2L3 6L8 10" stroke="var(--ink-2)" strokeWidth="1.6"
              strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        </div>
        <div style={{
          fontSize: 13, color: 'var(--ink-3)', fontWeight: 500, letterSpacing: '-0.01em',
        }}>질문하기</div>
        <div style={{ width: 36 }} />
      </div>

      <div style={{
        flex: 1, display: 'flex', flexDirection: 'column',
        padding: '28px 22px 0', position: 'relative', zIndex: 2,
      }}>
        {/* Prompt */}
        <div style={{
          fontFamily: 'var(--serif)', fontSize: 22, lineHeight: 1.5,
          color: 'var(--ink)', fontWeight: 500, letterSpacing: '-0.02em',
          marginBottom: 20, wordBreak: 'keep-all', textWrap: 'pretty',
        }}>
          <span style={{ color: 'var(--terra-deep)' }}>무엇이</span> 궁금하세요?<br/>
          <span style={{ color: 'var(--ink-3)', fontSize: 15, fontWeight: 400 }}>
            당신의 기록에서만 답을 찾아드립니다.
          </span>
        </div>

        {/* Input card */}
        <div style={{
          background: '#fff',
          borderRadius: 20,
          padding: '16px 16px 12px',
          border: focused ? '1px solid var(--terra)' : '0.5px solid var(--line-2)',
          boxShadow: focused
            ? '0 0 0 4px rgba(200, 116, 86, 0.1), var(--shadow-card)'
            : 'var(--shadow-soft)',
          transition: 'all 0.2s ease',
        }}>
          <textarea
            ref={inputRef}
            value={query}
            onChange={e => setQuery(e.target.value)}
            onFocus={() => setFocused(true)}
            onKeyDown={e => { if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); submit(); } }}
            placeholder="예) 지난 겨울엔 뭘 하면서 기분이 풀렸지?"
            rows={3}
            style={{
              width: '100%', border: 'none', outline: 'none', resize: 'none',
              fontFamily: 'var(--sans)', fontSize: 16, lineHeight: 1.55,
              color: 'var(--ink)', background: 'transparent',
              letterSpacing: '-0.01em',
            }}
          />
          <div style={{
            display: 'flex', alignItems: 'center', justifyContent: 'space-between',
            marginTop: 6, paddingTop: 10, borderTop: '0.5px solid var(--line)',
          }}>
            <div style={{ display: 'flex', gap: 8 }}>
              <div style={{
                width: 32, height: 32, borderRadius: '50%',
                background: 'var(--paper-2)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                cursor: 'pointer', color: 'var(--ink-2)',
              }}>
                <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
                  <rect x="6" y="2.5" width="4" height="7" rx="2" stroke="currentColor" strokeWidth="1.3"/>
                  <path d="M4 8C4 10.21 5.79 12 8 12C10.21 12 12 10.21 12 8M8 12V14"
                    stroke="currentColor" strokeWidth="1.3" strokeLinecap="round"/>
                </svg>
              </div>
              <div style={{
                width: 32, height: 32, borderRadius: '50%',
                background: 'var(--paper-2)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                cursor: 'pointer', color: 'var(--ink-2)',
              }}>
                <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
                  <rect x="2" y="3.5" width="12" height="9" rx="1.2" stroke="currentColor" strokeWidth="1.3"/>
                  <circle cx="10.5" cy="6.5" r="0.9" fill="currentColor"/>
                  <path d="M2.5 11L6 7.5L9 10.5L11 8.5L13.5 11"
                    stroke="currentColor" strokeWidth="1.3" strokeLinecap="round" strokeLinejoin="round"/>
                </svg>
              </div>
            </div>
            <button
              className="btn btn-terra"
              onClick={() => submit()}
              disabled={!query.trim()}
              style={{
                padding: '9px 18px',
                borderRadius: 999,
                fontSize: 14,
                fontWeight: 600,
                display: 'flex', alignItems: 'center', gap: 6,
                opacity: query.trim() ? 1 : 0.5,
              }}>
              묻기
              <svg width="12" height="12" viewBox="0 0 12 12" fill="none">
                <path d="M2 6H10M10 6L6 2M10 6L6 10" stroke="#FDF6EC" strokeWidth="1.6"
                  strokeLinecap="round" strokeLinejoin="round"/>
              </svg>
            </button>
          </div>
        </div>

        {/* Scope */}
        <div style={{
          marginTop: 18,
          display: 'flex', gap: 8, flexWrap: 'wrap',
        }}>
          <div style={{
            fontSize: 11, letterSpacing: '0.08em', color: 'var(--ink-3)',
            textTransform: 'uppercase', fontWeight: 600,
            width: '100%', marginBottom: 4,
          }}>검색 범위</div>
          {[
            { l: '전체 기간', active: true },
            { l: '지난 1년' },
            { l: '지난 한 달' },
            { l: '모든 소스', active: true },
          ].map((t, i) => (
            <div key={i} style={{
              padding: '6px 12px',
              borderRadius: 999,
              fontSize: 12,
              fontWeight: 500,
              letterSpacing: '-0.01em',
              background: t.active ? 'var(--terra)' : 'rgba(255,255,255,0.6)',
              color: t.active ? '#FDF6EC' : 'var(--ink-2)',
              border: t.active ? '0.5px solid var(--terra-deep)' : '0.5px solid var(--line)',
              cursor: 'pointer',
            }}>{t.l}</div>
          ))}
        </div>

        {/* Examples */}
        <div style={{ marginTop: 24, flex: 1 }}>
          <div style={{
            fontSize: 11, letterSpacing: '0.08em', color: 'var(--ink-3)',
            textTransform: 'uppercase', fontWeight: 600, marginBottom: 10,
          }}>이렇게 물어보세요</div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
            {samples.map((s, i) => (
              <div key={i}
                onClick={() => { setQuery(s.q); }}
                style={{
                  display: 'flex', alignItems: 'center', gap: 10,
                  padding: '11px 14px',
                  background: 'rgba(255,255,255,0.45)',
                  border: '0.5px solid var(--line)',
                  borderRadius: 12,
                  cursor: 'pointer',
                }}>
                <div className="tag terra" style={{ padding: '2px 7px', fontSize: 10, flexShrink: 0 }}>
                  {s.cat}
                </div>
                <div style={{
                  fontSize: 13.5, color: 'var(--ink)', fontWeight: 450,
                  letterSpacing: '-0.01em', flex: 1,
                }}>{s.q}</div>
              </div>
            ))}
          </div>
        </div>

        {/* Privacy */}
        <div style={{
          marginTop: 'auto', padding: '16px 0 20px',
          display: 'flex', alignItems: 'center', gap: 8,
          fontSize: 11, color: 'var(--ink-3)',
          textAlign: 'center', justifyContent: 'center',
        }}>
          <svg width="11" height="11" viewBox="0 0 11 11" fill="none">
            <path d="M5.5 1L1.5 3V5.5C1.5 7.5 3.2 9.5 5.5 10C7.8 9.5 9.5 7.5 9.5 5.5V3L5.5 1Z"
              stroke="var(--sage)" strokeWidth="1.2" strokeLinejoin="round"/>
          </svg>
          Gemma‑4‑E2B · 기기 안에서 처리됨
        </div>
      </div>
    </div>
  );
}

window.AskScreen = AskScreen;
