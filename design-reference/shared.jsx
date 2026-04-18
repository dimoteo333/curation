// Shared UI helpers for Curator

// Small logo mark — a "book + lens" warm glyph
function CuratorMark({ size = 24, color }) {
  const c = color || 'var(--terra)';
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <path d="M4 5.5C4 4.67 4.67 4 5.5 4H11V19H5.5C4.67 19 4 18.33 4 17.5V5.5Z" stroke={c} strokeWidth="1.5"/>
      <path d="M20 5.5C20 4.67 19.33 4 18.5 4H13V19H18.5C19.33 19 20 18.33 20 17.5V5.5Z" stroke={c} strokeWidth="1.5"/>
      <circle cx="12" cy="11.5" r="2.4" fill={c}/>
    </svg>
  );
}

function SourceIcon({ source, size = 14 }) {
  const style = { width: size, height: size };
  const stroke = 'currentColor';
  switch (source) {
    case 'diary':
      return (
        <svg viewBox="0 0 16 16" style={style} fill="none">
          <path d="M3 2.5C3 2.22 3.22 2 3.5 2H12.5C12.78 2 13 2.22 13 2.5V13.5C13 13.78 12.78 14 12.5 14H3.5C3.22 14 3 13.78 3 13.5V2.5Z" stroke={stroke} strokeWidth="1.2"/>
          <path d="M5.5 5H10.5M5.5 7.5H10.5M5.5 10H8.5" stroke={stroke} strokeWidth="1.2" strokeLinecap="round"/>
        </svg>
      );
    case 'calendar':
      return (
        <svg viewBox="0 0 16 16" style={style} fill="none">
          <rect x="2.5" y="3.5" width="11" height="10" rx="1" stroke={stroke} strokeWidth="1.2"/>
          <path d="M5.5 2V5M10.5 2V5M2.5 7H13.5" stroke={stroke} strokeWidth="1.2" strokeLinecap="round"/>
        </svg>
      );
    case 'memo':
      return (
        <svg viewBox="0 0 16 16" style={style} fill="none">
          <path d="M3 3.5C3 2.67 3.67 2 4.5 2H11.5C12.33 2 13 2.67 13 3.5V11L10 14H4.5C3.67 14 3 13.33 3 12.5V3.5Z" stroke={stroke} strokeWidth="1.2"/>
          <path d="M10 11H13L10 14V11Z" fill={stroke} opacity="0.3"/>
        </svg>
      );
    case 'voice_memo':
      return (
        <svg viewBox="0 0 16 16" style={style} fill="none">
          <rect x="6" y="2.5" width="4" height="7" rx="2" stroke={stroke} strokeWidth="1.2"/>
          <path d="M4 8C4 10.21 5.79 12 8 12C10.21 12 12 10.21 12 8M8 12V14" stroke={stroke} strokeWidth="1.2" strokeLinecap="round"/>
        </svg>
      );
    case 'photo':
      return (
        <svg viewBox="0 0 16 16" style={style} fill="none">
          <rect x="2" y="3.5" width="12" height="9" rx="1.2" stroke={stroke} strokeWidth="1.2"/>
          <circle cx="10.5" cy="6.5" r="0.9" fill={stroke}/>
          <path d="M2.5 11L6 7.5L9 10.5L11 8.5L13.5 11" stroke={stroke} strokeWidth="1.2" strokeLinecap="round" strokeLinejoin="round"/>
        </svg>
      );
    default:
      return null;
  }
}

// Nav dock (iOS bottom)
function NavDock({ active, onNav }) {
  const items = [
    { id: 'home', label: '오늘', icon: (
      <svg width="22" height="22" viewBox="0 0 22 22" fill="none">
        <path d="M3 9L11 3L19 9V18C19 18.55 18.55 19 18 19H4C3.45 19 3 18.55 3 18V9Z"
          stroke="currentColor" strokeWidth="1.6" strokeLinejoin="round"/>
      </svg>
    )},
    { id: 'ask', label: '질문', icon: (
      <svg width="22" height="22" viewBox="0 0 22 22" fill="none">
        <circle cx="10" cy="10" r="6.5" stroke="currentColor" strokeWidth="1.6"/>
        <path d="M15 15L19 19" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round"/>
      </svg>
    )},
    { id: 'timeline', label: '타임라인', icon: (
      <svg width="22" height="22" viewBox="0 0 22 22" fill="none">
        <path d="M5 4V18M5 4H17M5 11H15M5 18H13" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round"/>
      </svg>
    )},
    { id: 'settings', label: '설정', icon: (
      <svg width="22" height="22" viewBox="0 0 22 22" fill="none">
        <circle cx="11" cy="11" r="3" stroke="currentColor" strokeWidth="1.6"/>
        <path d="M11 2V4M11 18V20M2 11H4M18 11H20M4.6 4.6L6 6M16 16L17.4 17.4M4.6 17.4L6 16M16 6L17.4 4.6"
          stroke="currentColor" strokeWidth="1.6" strokeLinecap="round"/>
      </svg>
    )},
  ];
  return (
    <div className="dock">
      {items.map(it => (
        <div key={it.id}
          className={'dock-btn' + (active === it.id ? ' active' : '')}
          onClick={() => onNav && onNav(it.id)}>
          {it.icon}
          <div>{it.label}</div>
        </div>
      ))}
    </div>
  );
}

Object.assign(window, { CuratorMark, SourceIcon, NavDock });
