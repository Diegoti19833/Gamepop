import React from 'react'
import { Play } from 'lucide-react'

export default function TrailCard({ title, progress = 0, xp = 0, level = 1, icon, onContinue }) {
  const pct = Math.max(0, Math.min(100, progress))
  const fallbackIcon = title?.toLowerCase().includes('venda') ? '💰' : title?.toLowerCase().includes('produto') ? '🦴' : '🐾'
  return (
    <div
      className="bg-white rounded-2xl p-4 text-center transition-transform hover:-translate-y-0.5"
      style={{ border: '2px solid rgba(0,146,74,.25)', boxShadow: '0 8px 24px rgba(0,0,0,.08)' }}
    >
      <div style={{display:'grid', placeItems:'center'}}>
        <div className="icon-circle" style={{width:44, height:44, fontSize:20}} aria-hidden>
          {icon || fallbackIcon}
        </div>
      </div>

      <div className="title" style={{ fontSize: 16, marginTop:8 }}>{title}</div>
      <div className="subtitle" style={{ fontSize: 12, color: 'var(--muted)' }}>Nível {level} • {xp} XP</div>

      <div className="rounded-full overflow-hidden" style={{ marginTop: 10, height: 10, background: '#ffffff', border: '1px solid #e5ece8' }}>
        <div style={{ height: '100%', width: `${pct}%`, background: 'linear-gradient(90deg, #00924A, #00b563)', transition: 'width .4s ease' }} />
      </div>

      <div style={{display:'flex', justifyContent:'center', gap:8, marginTop:10}}>
        <span className="badge" style={{padding:'6px 8px'}}><span aria-hidden>🥇</span> Conquista</span>
        <span className="badge" style={{padding:'6px 8px'}}><span aria-hidden>⭐</span> Destaque</span>
      </div>

      <button
        className="btn btn-secondary"
        style={{ marginTop: 10, display:'inline-flex', alignItems:'center', gap:8, transition:'transform .12s ease, box-shadow .12s ease' }}
        onClick={onContinue}
        onMouseDown={(e)=>{ e.currentTarget.style.transform='scale(0.98)'}}
        onMouseUp={(e)=>{ e.currentTarget.style.transform='scale(1)'}}
      >
        <Play size={18}/> Continuar de onde parei
      </button>
    </div>
  )
}