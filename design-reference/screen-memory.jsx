// MemorySheet — bottom sheet with the full memory record (displayed over the answer)
function MemorySheet({ memoryId, onClose }) {
  const { MEMORIES } = window.CURATOR_DATA;
  if (!memoryId) return null;
  const m = MEMORIES[memoryId];
  if (!m) return null;

  return (
    <div style={{
      position: 'absolute', inset: 0, zIndex: 100,
      display: 'flex', alignItems: 'flex-end',
      pointerEvents: 'auto',
    }}>
      {/* overlay */}
      <div className="overlay"
        onClick={onClose}
        style={{
          position: 'absolute', inset: 0,
          background: 'rgba(42, 31, 23, 0.35)',
          backdropFilter: 'blur(3px)',
        }}
      />
      {/* sheet */}
      <div className="sheet paper" style={{
        position: 'relative', width: '100%',
        maxHeight: '85%', minHeight: '65%',
        borderTopLeftRadius: 28, borderTopRightRadius: 28,
        boxShadow: '0 -20px 50px rgba(0,0,0,0.2)',
        display: 'flex', flexDirection: 'column',
        overflow: 'hidden',
      }}>
        <div className="paper-grain" />
        {/* grabber */}
        <div style={{ padding: '8px 0 4px', display: 'flex', justifyContent: 'center' }}>
          <div style={{ width: 36, height: 4, borderRadius: 2, background: 'var(--ink-4)', opacity: 0.5 }}/>
        </div>

        {/* header row */}
        <div style={{
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          padding: '8px 18px 14px', position: 'relative', zIndex: 2,
        }}>
          <div style={{
            display: 'flex', alignItems: 'center', gap: 8,
            padding: '5px 11px', borderRadius: 999,
            background: 'rgba(200, 116, 86, 0.1)',
            color: 'var(--terra-deep)',
            fontSize: 11, fontWeight: 600, letterSpacing: '-0.01em',
          }}>
            <SourceIcon source={m.source} size={12}/>
            {m.sourceLabel}
          </div>
          <div onClick={onClose} style={{
            width: 30, height: 30, borderRadius: '50%',
            background: 'rgba(42, 31, 23, 0.08)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            cursor: 'pointer',
          }}>
            <svg width="12" height="12" viewBox="0 0 12 12" fill="none">
              <path d="M2 2L10 10M10 2L2 10" stroke="var(--ink-2)" strokeWidth="1.5" strokeLinecap="round"/>
            </svg>
          </div>
        </div>

        {/* scroll body */}
        <div className="scroll" style={{ flex: 1, padding: '0 22px 28px', position: 'relative', zIndex: 2 }}>
          {/* date + meta */}
          <div style={{
            fontSize: 12, color: 'var(--ink-3)', fontWeight: 500,
            letterSpacing: '0.01em', marginBottom: 4,
            display: 'flex', alignItems: 'center', gap: 8,
          }}>
            <span>{m.date}</span>
            <div className="divider-dot"/>
            <span>{m.location}</span>
          </div>

          {/* title */}
          <div className="title" style={{
            fontSize: 26, lineHeight: 1.35, marginTop: 4, marginBottom: 14,
            wordBreak: 'keep-all', textWrap: 'pretty',
          }}>{m.title}</div>

          {/* mood + tags */}
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, marginBottom: 18 }}>
            <div className="tag terra">
              <svg width="10" height="10" viewBox="0 0 10 10" fill="none">
                <circle cx="5" cy="5" r="3.5" stroke="currentColor" strokeWidth="1.1"/>
                <circle cx="4" cy="4.5" r="0.5" fill="currentColor"/>
                <circle cx="6" cy="4.5" r="0.5" fill="currentColor"/>
                <path d="M3.5 6.5C4 7 4.5 7.2 5 7.2C5.5 7.2 6 7 6.5 6.5" stroke="currentColor" strokeWidth="1" strokeLinecap="round"/>
              </svg>
              {m.mood}
            </div>
            {m.tags.map((t, i) => (
              <div key={i} className="tag">#{t}</div>
            ))}
          </div>

          {/* placeholder image block — keeps the soft product-shot card aesthetic */}
          <div className="memory-placeholder" style={{
            height: 100, borderRadius: 14, marginBottom: 18,
            border: '0.5px solid var(--line-2)',
          }}>
            <div style={{
              position: 'absolute', inset: 0,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              background: 'rgba(245, 237, 224, 0.6)',
            }}>
              <div style={{ textAlign: 'center' }}>
                <div style={{ marginBottom: 2 }}>Attached photo</div>
                <div style={{ fontSize: 9, opacity: 0.7 }}>{m.dateShort} · 2 items</div>
              </div>
            </div>
          </div>

          {/* content */}
          <div style={{
            fontFamily: 'var(--serif)', fontSize: 16, lineHeight: 1.8,
            color: 'var(--ink)', letterSpacing: '-0.005em',
            wordBreak: 'keep-all', textWrap: 'pretty',
          }}>
            {m.content}
          </div>

          {/* actions */}
          <div style={{
            marginTop: 22, padding: '14px 0 0',
            borderTop: '0.5px solid var(--line)',
            display: 'flex', gap: 8,
          }}>
            <div style={{
              flex: 1, padding: '10px 12px', borderRadius: 12,
              background: 'rgba(255,255,255,0.55)',
              border: '0.5px solid var(--line)',
              display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
              fontSize: 13, fontWeight: 500, color: 'var(--ink-2)', cursor: 'pointer',
            }}>
              <svg width="13" height="13" viewBox="0 0 13 13" fill="none">
                <path d="M6.5 1V8.5M6.5 8.5L3.5 5.5M6.5 8.5L9.5 5.5M2 11H11"
                  stroke="currentColor" strokeWidth="1.4" strokeLinecap="round"/>
              </svg>
              내보내기
            </div>
            <div style={{
              flex: 1, padding: '10px 12px', borderRadius: 12,
              background: 'rgba(255,255,255,0.55)',
              border: '0.5px solid var(--line)',
              display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
              fontSize: 13, fontWeight: 500, color: 'var(--ink-2)', cursor: 'pointer',
            }}>
              <svg width="13" height="13" viewBox="0 0 13 13" fill="none">
                <path d="M6.5 2V8M6.5 2L4 4.5M6.5 2L9 4.5M2.5 10V11H10.5V10"
                  stroke="currentColor" strokeWidth="1.4" strokeLinecap="round" strokeLinejoin="round"/>
              </svg>
              이 기록 제외
            </div>
            <div style={{
              padding: '10px 14px', borderRadius: 12,
              background: 'var(--terra)', color: '#FDF6EC',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontSize: 13, fontWeight: 600, cursor: 'pointer',
            }}>원문 열기</div>
          </div>
        </div>
      </div>
    </div>
  );
}

window.MemorySheet = MemorySheet;
