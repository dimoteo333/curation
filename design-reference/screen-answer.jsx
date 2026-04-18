// AnswerScreen — essay/letter-style reflection with inline tappable citations.
// Citations are [[id]] tokens in the essay template; we parse and render them as <cite> chips.

function AnswerScreen({ query, onBack, onOpenMemory, streamingDone }) {
  const { MEMORIES } = window.CURATOR_DATA;

  // Essay content: structured so we can stream it word by word.
  // Citation tokens: {{CITE:id}}
  const ESSAY_PARAGRAPHS = [
    '지원 님의 일기를 다시 훑어보며 드리는 작은 편지입니다.',
    '요즘 느끼시는 그 무거움은, 이번이 처음은 아닌 것 같아요. 3년 전 이맘때쯤에도 비슷한 기록이 있었습니다. {{CITE:m_2023_02_14}} 아침에 눈뜨기 힘들고, 점심을 자주 거르고, 저녁엔 아무것도 하기 싫다고 쓰셨어요. 그 시기가 약 2주 이어졌다고 적혀 있네요.',
    '흥미로운 건, 그 뒤 한 달쯤 지나 상황이 조금씩 바뀌었다는 점이에요. 3월엔 오래 미뤄둔 작은 사이드 프로젝트를 시작하셨고 {{CITE:m_2023_03_21}}, 그 주말에 “오랜만에 뭔가 만든다는 감각이 좋았다”라고 적으셨습니다. 4월엔 친구와 한강 산책을 다시 시작하셨고요. {{CITE:m_2023_04_09}}',
    '그때의 회복은 거창한 결심보다 가볍고 구체적인 행동에서 왔어요. 만들고 싶었던 작은 것을 하나 시작하는 일, 약속 하나를 잡고 몸을 움직이는 일. 지원 님의 기록을 토대로 추측해보면, 지금도 비슷한 실마리가 도움이 될 수 있을 것 같습니다.',
    '한 가지 더, 작년 11월 이직 직후에도 {{CITE:m_2024_11_18}} 비슷한 결의 기록이 보여요. 새 환경에 몸이 익숙해지는 동안 에너지가 많이 빠지는 시기가 지원 님께는 종종 찾아오는 듯합니다. 이 패턴을 기억해두시면, 같은 감정이 올 때 덜 놀라실 수 있을 거예요.',
  ];

  const CITED_IDS = ['m_2023_02_14', 'm_2023_03_21', 'm_2023_04_09', 'm_2024_11_18'];

  const [revealed, setRevealed] = React.useState(streamingDone ? ESSAY_PARAGRAPHS.length : 0);
  const [streaming, setStreaming] = React.useState(!streamingDone);

  React.useEffect(() => {
    if (streamingDone) { setRevealed(ESSAY_PARAGRAPHS.length); setStreaming(false); return; }
    // Simulate paragraph-by-paragraph streaming
    setRevealed(0); setStreaming(true);
    let i = 0;
    const t = setInterval(() => {
      i++;
      setRevealed(i);
      if (i >= ESSAY_PARAGRAPHS.length) {
        clearInterval(t);
        setStreaming(false);
      }
    }, 850);
    return () => clearInterval(t);
  }, []);

  // render a paragraph: parse {{CITE:id}} tokens
  function renderParagraph(text, pi) {
    const parts = [];
    const re = /\{\{CITE:([a-z0-9_]+)\}\}/g;
    let last = 0, m, citeIdx = 0;
    while ((m = re.exec(text)) !== null) {
      if (m.index > last) parts.push(<span key={'t' + pi + '_' + last}>{text.slice(last, m.index)}</span>);
      const id = m[1];
      const globalIdx = CITED_IDS.indexOf(id) + 1;
      parts.push(
        <span key={'c' + pi + '_' + m.index}
          className="cite"
          onClick={() => onOpenMemory(id)}>
          <svg width="9" height="9" viewBox="0 0 9 9" fill="none" style={{ flexShrink: 0 }}>
            <rect x="1.5" y="1" width="6" height="7" rx="0.8" stroke="currentColor" strokeWidth="1"/>
            <path d="M3 3.5H6M3 5H6M3 6.5H4.5" stroke="currentColor" strokeWidth="0.9" strokeLinecap="round"/>
          </svg>
          {globalIdx}
        </span>
      );
      last = m.index + m[0].length;
      citeIdx++;
    }
    if (last < text.length) parts.push(<span key={'t' + pi + '_end'}>{text.slice(last)}</span>);
    return parts;
  }

  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', position: 'relative' }}>
      <div className="paper-grain" />
      <div style={{ height: 54 }} />

      {/* Header */}
      <div style={{
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        padding: '10px 16px 10px', position: 'relative', zIndex: 5,
      }}>
        <div onClick={onBack} style={{
          width: 36, height: 36, borderRadius: '50%',
          background: 'rgba(255,255,255,0.65)', border: '0.5px solid var(--line)',
          display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer',
        }}>
          <svg width="12" height="12" viewBox="0 0 12 12" fill="none">
            <path d="M8 2L3 6L8 10" stroke="var(--ink-2)" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        </div>
        <div style={{
          display: 'flex', alignItems: 'center', gap: 6,
          fontSize: 12, color: 'var(--ink-3)', fontWeight: 500,
        }}>
          {streaming ? (
            <>
              <div style={{ display: 'flex', gap: 3 }}>
                {[0, 1, 2].map(i => (
                  <div key={i} style={{
                    width: 4, height: 4, borderRadius: 2, background: 'var(--terra)',
                    animation: `bar 0.9s ${i * 0.12}s infinite ease-in-out`,
                    transformOrigin: 'bottom',
                  }}/>
                ))}
              </div>
              생각 중…
            </>
          ) : (
            <>4개의 기록을 참고함</>
          )}
        </div>
        <div style={{
          width: 36, height: 36, borderRadius: '50%',
          background: 'rgba(255,255,255,0.65)', border: '0.5px solid var(--line)',
          display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer',
        }}>
          <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
            <path d="M10 4.5L11.5 3L8 6.5M6 8.5L2.5 12L4 10.5M10 4.5L13 7.5L9.5 11L4 12.5L5.5 7L9 3.5L10 4.5Z"
              stroke="var(--ink-2)" strokeWidth="1.3" strokeLinejoin="round"/>
          </svg>
        </div>
      </div>

      {/* Scrollable essay */}
      <div className="scroll" style={{ flex: 1, paddingBottom: 120 }}>
        <div style={{ padding: '10px 24px 0' }}>
          {/* query card */}
          <div style={{
            background: 'rgba(200, 116, 86, 0.08)',
            border: '0.5px solid rgba(200, 116, 86, 0.2)',
            borderRadius: 14,
            padding: '12px 14px',
            marginBottom: 24,
          }}>
            <div style={{
              fontSize: 10, letterSpacing: '0.1em', color: 'var(--terra-deep)',
              textTransform: 'uppercase', fontWeight: 700, marginBottom: 4,
            }}>질문</div>
            <div style={{
              fontFamily: 'var(--serif)', fontSize: 17, color: 'var(--ink)',
              fontWeight: 500, lineHeight: 1.5, letterSpacing: '-0.01em',
              wordBreak: 'keep-all',
            }}>{query || '나 요즘 왜 이렇게 무기력하지?'}</div>
          </div>

          {/* essay */}
          <div className="essay">
            {ESSAY_PARAGRAPHS.slice(0, revealed).map((p, i) => (
              <p key={i} style={{
                opacity: 0, animation: 'fadeIn 0.5s forwards',
              }}>
                {renderParagraph(p, i)}
                {i === revealed - 1 && streaming && <span className="caret" />}
              </p>
            ))}
          </div>

          {/* Citation list */}
          {!streaming && (
            <div style={{ marginTop: 28 }}>
              <div style={{
                fontSize: 11, letterSpacing: '0.08em', color: 'var(--ink-3)',
                textTransform: 'uppercase', fontWeight: 600, marginBottom: 10,
                display: 'flex', alignItems: 'center', gap: 6,
              }}>
                참고한 기록
                <div style={{
                  fontSize: 10, padding: '1px 6px', borderRadius: 4,
                  background: 'var(--paper-2)', color: 'var(--ink-3)',
                  letterSpacing: 0,
                }}>{CITED_IDS.length}</div>
              </div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                {CITED_IDS.map((id, i) => {
                  const m = MEMORIES[id];
                  return (
                    <div key={id}
                      onClick={() => onOpenMemory(id)}
                      style={{
                        background: '#fff',
                        border: '0.5px solid var(--line)',
                        borderRadius: 14,
                        padding: '12px 14px',
                        display: 'flex', gap: 12,
                        boxShadow: 'var(--shadow-soft)',
                        cursor: 'pointer',
                      }}>
                      <div style={{
                        width: 36, height: 36, borderRadius: 10,
                        background: 'var(--terra)',
                        color: '#FDF6EC',
                        display: 'flex', alignItems: 'center', justifyContent: 'center',
                        fontFamily: 'var(--serif)', fontSize: 15, fontWeight: 600,
                        flexShrink: 0,
                      }}>{i + 1}</div>
                      <div style={{ flex: 1, minWidth: 0 }}>
                        <div style={{
                          display: 'flex', alignItems: 'center', gap: 6, marginBottom: 3,
                        }}>
                          <div style={{ color: 'var(--ink-3)' }}>
                            <SourceIcon source={m.source} size={12} />
                          </div>
                          <div style={{ fontSize: 11, color: 'var(--ink-3)', fontWeight: 500 }}>
                            {m.sourceLabel} · {m.dateShort}
                          </div>
                          <div style={{ flex: 1 }}/>
                          <div style={{
                            fontSize: 10, padding: '1px 6px', borderRadius: 999,
                            background: 'var(--paper-2)', color: 'var(--ink-3)', fontWeight: 500,
                          }}>{m.mood}</div>
                        </div>
                        <div style={{
                          fontSize: 14, color: 'var(--ink)', fontWeight: 500,
                          letterSpacing: '-0.01em', marginBottom: 2,
                          overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
                        }}>{m.title}</div>
                        <div style={{
                          fontSize: 12, color: 'var(--ink-2)',
                          display: '-webkit-box', WebkitLineClamp: 1, WebkitBoxOrient: 'vertical',
                          overflow: 'hidden', letterSpacing: '-0.01em',
                        }}>{m.content}</div>
                      </div>
                    </div>
                  );
                })}
              </div>

              {/* Feedback */}
              <div style={{
                marginTop: 20, padding: '14px 16px',
                background: 'rgba(255,255,255,0.55)',
                border: '0.5px solid var(--line)',
                borderRadius: 14,
                display: 'flex', alignItems: 'center', justifyContent: 'space-between',
              }}>
                <div>
                  <div style={{ fontSize: 13, fontWeight: 500, color: 'var(--ink)', marginBottom: 2 }}>
                    답변이 도움이 되었나요?
                  </div>
                  <div style={{ fontSize: 11, color: 'var(--ink-3)' }}>
                    기록 검색 품질을 개선하는 데 사용됩니다
                  </div>
                </div>
                <div style={{ display: 'flex', gap: 6 }}>
                  {['👍', '👎'].map((e, i) => (
                    <div key={i} style={{
                      width: 36, height: 36, borderRadius: 10,
                      background: 'var(--paper-2)',
                      border: '0.5px solid var(--line)',
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                      fontSize: 16, cursor: 'pointer',
                    }}>{e}</div>
                  ))}
                </div>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Follow-up input */}
      <div style={{
        position: 'absolute', bottom: 0, left: 0, right: 0, zIndex: 5,
        background: 'linear-gradient(to top, var(--paper) 60%, transparent)',
        padding: '16px 20px 28px',
      }}>
        <div style={{
          display: 'flex', alignItems: 'center', gap: 8,
          background: '#fff',
          borderRadius: 999,
          padding: '6px 6px 6px 16px',
          border: '0.5px solid var(--line-2)',
          boxShadow: 'var(--shadow-card)',
        }}>
          <div style={{
            flex: 1, fontSize: 14, color: 'var(--ink-3)', fontWeight: 400,
            letterSpacing: '-0.01em',
          }}>더 물어보기…</div>
          <div style={{
            width: 34, height: 34, borderRadius: '50%',
            background: 'var(--paper-2)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            color: 'var(--ink-2)', cursor: 'pointer',
          }}>
            <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
              <rect x="5" y="2" width="4" height="7" rx="2" stroke="currentColor" strokeWidth="1.3"/>
              <path d="M3 7C3 9.21 4.79 11 7 11C9.21 11 11 9.21 11 7M7 11V13"
                stroke="currentColor" strokeWidth="1.3" strokeLinecap="round"/>
            </svg>
          </div>
          <div style={{
            width: 34, height: 34, borderRadius: '50%',
            background: 'var(--terra)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            cursor: 'pointer',
          }}>
            <svg width="12" height="12" viewBox="0 0 12 12" fill="none">
              <path d="M6 9V3M6 3L3 6M6 3L9 6" stroke="#FDF6EC" strokeWidth="1.5"
                strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
          </div>
        </div>
      </div>

      <style>{`
        @keyframes fadeIn {
          from { opacity: 0; transform: translateY(6px); }
          to { opacity: 1; transform: translateY(0); }
        }
      `}</style>
    </div>
  );
}

window.AnswerScreen = AnswerScreen;
