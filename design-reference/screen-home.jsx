// HomeScreen — today dashboard, recent questions, warm hero
function HomeScreen({ onAsk, onOpenMemory, onNav }) {
  const { CHAT_HISTORY } = window.CURATOR_DATA;

  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', position: 'relative' }}>
      <div className="paper-grain" />
      {/* Status spacer */}
      <div style={{ height: 54 }} />

      {/* Top bar */}
      <div style={{
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        padding: '14px 20px 8px', position: 'relative', zIndex: 5,
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <CuratorMark size={22} />
          <div style={{
            fontFamily: 'var(--serif)', fontWeight: 600, fontSize: 17,
            color: 'var(--ink)', letterSpacing: '-0.01em',
          }}>큐레이터</div>
        </div>
        <div style={{
          width: 36, height: 36, borderRadius: 10, background: 'var(--paper-2)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          border: '0.5px solid var(--line)',
        }}>
          <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
            <circle cx="8" cy="6" r="2.5" stroke="var(--ink-2)" strokeWidth="1.3"/>
            <path d="M3 13.5C3.8 11.4 5.7 10 8 10C10.3 10 12.2 11.4 13 13.5"
              stroke="var(--ink-2)" strokeWidth="1.3" strokeLinecap="round"/>
          </svg>
        </div>
      </div>

      <div className="scroll" style={{ flex: 1, paddingBottom: 100 }}>
        {/* Greeting */}
        <div style={{ padding: '18px 20px 0' }}>
          <div style={{
            fontSize: 12, color: 'var(--ink-3)', letterSpacing: '0.01em', marginBottom: 6,
          }}>2026년 4월 18일 토요일</div>
          <div style={{
            fontFamily: 'var(--serif)', fontSize: 28, lineHeight: 1.35,
            color: 'var(--ink)', fontWeight: 500, letterSpacing: '-0.02em',
            wordBreak: 'keep-all', textWrap: 'pretty',
          }}>
            안녕하세요, 지원 님.<br/>
            <span style={{ color: 'var(--ink-3)' }}>오늘은 어떤 마음을<br/>들여다보고 싶으세요?</span>
          </div>
        </div>

        {/* Big Ask card */}
        <div style={{ padding: '22px 20px 0' }}>
          <div
            onClick={onAsk}
            style={{
              background: 'var(--paper)',
              border: '0.5px solid var(--line-2)',
              borderRadius: 22,
              padding: '18px 18px 16px',
              boxShadow: 'var(--shadow-soft)',
              cursor: 'pointer',
              position: 'relative',
              overflow: 'hidden',
            }}>
            {/* accent corner */}
            <div style={{
              position: 'absolute', top: -40, right: -40, width: 120, height: 120,
              borderRadius: '50%',
              background: 'radial-gradient(circle, rgba(200,116,86,0.18), transparent 65%)',
            }}/>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 10 }}>
              <div style={{
                width: 6, height: 6, borderRadius: 3, background: 'var(--terra)',
              }}/>
              <div style={{
                fontSize: 11, letterSpacing: '0.1em', color: 'var(--terra-deep)',
                textTransform: 'uppercase', fontWeight: 600,
              }}>오늘의 질문</div>
            </div>
            <div style={{
              fontFamily: 'var(--serif)', fontSize: 18, lineHeight: 1.55,
              color: 'var(--ink)', fontWeight: 500, marginBottom: 14,
              letterSpacing: '-0.01em', wordBreak: 'keep-all',
            }}>
              내 기록에 물어보세요.<br/>
              <span style={{ color: 'var(--ink-2)', fontWeight: 400 }}>
                오늘의 감정, 과거의 나, 반복되는 패턴까지.
              </span>
            </div>
            <div style={{
              display: 'flex', alignItems: 'center',
              background: '#fff', borderRadius: 14,
              padding: '12px 14px', gap: 10,
              border: '0.5px solid var(--line)',
            }}>
              <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
                <circle cx="7" cy="7" r="5" stroke="var(--ink-3)" strokeWidth="1.3"/>
                <path d="M11 11L14 14" stroke="var(--ink-3)" strokeWidth="1.3" strokeLinecap="round"/>
              </svg>
              <div style={{
                flex: 1, fontSize: 14, color: 'var(--ink-3)',
                fontWeight: 400, letterSpacing: '-0.01em',
              }}>
                무엇이든 물어보세요…
              </div>
              <div style={{
                width: 28, height: 28, borderRadius: '50%',
                background: 'var(--terra)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                <svg width="12" height="12" viewBox="0 0 12 12" fill="none">
                  <path d="M6 9V3M6 3L3 6M6 3L9 6" stroke="#FDF6EC" strokeWidth="1.5"
                    strokeLinecap="round" strokeLinejoin="round"/>
                </svg>
              </div>
            </div>
          </div>
        </div>

        {/* Suggested prompts */}
        <div style={{ padding: '20px 20px 0' }}>
          <div style={{
            fontSize: 11, letterSpacing: '0.08em', color: 'var(--ink-3)',
            textTransform: 'uppercase', fontWeight: 600, marginBottom: 10,
          }}>추천 질문</div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            {[
              { q: '나 요즘 왜 이렇게 무기력하지?', hint: '감정 · 패턴' },
              { q: '작년 봄에 뭐 하면서 즐거웠지?', hint: '시간 · 회상' },
              { q: '지난달 내 루틴은 어땠을까?', hint: '행동 · 요약' },
            ].map((s, i) => (
              <div key={i} onClick={onAsk} style={{
                display: 'flex', alignItems: 'center', gap: 12,
                padding: '13px 14px',
                background: 'rgba(255,255,255,0.55)',
                borderRadius: 14,
                border: '0.5px solid var(--line)',
                cursor: 'pointer',
              }}>
                <div style={{
                  width: 28, height: 28, borderRadius: 8,
                  background: 'var(--paper-2)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  flexShrink: 0, color: 'var(--terra-deep)',
                }}>
                  <svg width="13" height="13" viewBox="0 0 13 13" fill="none">
                    <path d="M2 6.5L4.5 9L11 2.5" stroke="currentColor" strokeWidth="1.5"
                      strokeLinecap="round" strokeLinejoin="round"/>
                  </svg>
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{
                    fontSize: 14, fontWeight: 500, color: 'var(--ink)',
                    letterSpacing: '-0.01em', marginBottom: 2,
                    overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
                  }}>{s.q}</div>
                  <div style={{ fontSize: 11, color: 'var(--ink-3)' }}>{s.hint}</div>
                </div>
                <svg width="10" height="10" viewBox="0 0 10 10" fill="none" style={{ color: 'var(--ink-4)' }}>
                  <path d="M3 1L7 5L3 9" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round"/>
                </svg>
              </div>
            ))}
          </div>
        </div>

        {/* Recent conversations */}
        <div style={{ padding: '24px 20px 0' }}>
          <div style={{
            display: 'flex', alignItems: 'center', justifyContent: 'space-between',
            marginBottom: 10,
          }}>
            <div style={{
              fontSize: 11, letterSpacing: '0.08em', color: 'var(--ink-3)',
              textTransform: 'uppercase', fontWeight: 600,
            }}>최근 대화</div>
            <div style={{ fontSize: 12, color: 'var(--terra-deep)', fontWeight: 500 }}>
              전체 보기
            </div>
          </div>
          <div style={{
            background: '#fff', borderRadius: 18,
            border: '0.5px solid var(--line)',
            overflow: 'hidden',
            boxShadow: 'var(--shadow-soft)',
          }}>
            {CHAT_HISTORY.map((c, i) => (
              <div key={i} style={{
                padding: '13px 16px',
                borderTop: i > 0 ? '0.5px solid var(--line)' : 'none',
                cursor: 'pointer',
              }}>
                <div style={{
                  display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                  marginBottom: 4,
                }}>
                  <div style={{
                    fontSize: 13.5, color: 'var(--ink)', fontWeight: 500,
                    letterSpacing: '-0.01em', flex: 1, paddingRight: 8,
                    overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
                  }}>{c.q}</div>
                  <div style={{ fontSize: 11, color: 'var(--ink-3)', flexShrink: 0 }}>{c.when}</div>
                </div>
                <div style={{
                  fontSize: 12, color: 'var(--ink-2)',
                  overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
                  letterSpacing: '-0.01em',
                }}>{c.preview}</div>
              </div>
            ))}
          </div>
        </div>

        {/* Connected sources strip */}
        <div style={{ padding: '24px 20px 40px' }}>
          <div style={{
            fontSize: 11, letterSpacing: '0.08em', color: 'var(--ink-3)',
            textTransform: 'uppercase', fontWeight: 600, marginBottom: 10,
          }}>연결된 기록</div>
          <div style={{
            display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8,
          }}>
            {[
              { k: 'diary', l: '일기', n: '142' },
              { k: 'calendar', l: '캘린더', n: '318' },
              { k: 'memo', l: '메모', n: '87' },
              { k: 'voice_memo', l: '음성 메모', n: '24' },
            ].map((s, i) => (
              <div key={i} style={{
                padding: '12px 14px',
                background: 'rgba(255,255,255,0.55)',
                borderRadius: 14,
                border: '0.5px solid var(--line)',
                display: 'flex', alignItems: 'center', gap: 10,
              }}>
                <div style={{
                  width: 30, height: 30, borderRadius: 9,
                  background: 'var(--paper-2)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  color: 'var(--terra-deep)',
                }}>
                  <SourceIcon source={s.k} size={15}/>
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 12, color: 'var(--ink-3)' }}>{s.l}</div>
                  <div style={{
                    fontFamily: 'var(--serif)', fontSize: 16, fontWeight: 500,
                    color: 'var(--ink)', letterSpacing: '-0.01em',
                  }}>{s.n}<span style={{
                    fontSize: 10, color: 'var(--ink-3)', fontWeight: 400,
                    fontFamily: 'var(--sans)', marginLeft: 3,
                  }}>개</span></div>
                </div>
              </div>
            ))}
          </div>
          <div style={{
            marginTop: 12, fontSize: 11, color: 'var(--ink-3)',
            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
          }}>
            <svg width="10" height="10" viewBox="0 0 10 10" fill="none">
              <path d="M5 1L1.5 3V5C1.5 7 3 8.5 5 9C7 8.5 8.5 7 8.5 5V3L5 1Z"
                stroke="var(--sage)" strokeWidth="1.2" strokeLinejoin="round"/>
            </svg>
            모든 처리가 기기 안에서 이루어집니다
          </div>
        </div>
      </div>

      {/* Bottom dock */}
      <div style={{ position: 'absolute', bottom: 0, left: 0, right: 0, paddingBottom: 24 }}>
        <NavDock active="home" onNav={onNav}/>
      </div>
    </div>
  );
}

window.HomeScreen = HomeScreen;
