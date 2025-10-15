import { useState } from 'react'
import { BrowserRouter, Routes, Route, NavLink, useNavigate, Navigate } from 'react-router-dom'
import './index.css'
// (removido) import bgLogin from './assets/login-bg.jpg'
import { Headphones, ShoppingBag, PawPrint } from 'lucide-react'
import TrailsSection from './components/trails/TrailsSection'

const IconHome = () => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M3 10.5 12 3l9 7.5"/><path d="M5 10v10h14V10"/></svg>
)
const IconTrails = () => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M4 6h16"/><path d="M4 12h16"/><path d="M4 18h16"/></svg>
)
const IconRank = () => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M7 21V10"/><path d="M12 21V3"/><path d="M17 21v-6"/></svg>
)
const IconUser = () => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M12 12a5 5 0 1 0 0-10 5 5 0 0 0 0 10Z"/><path d="M4 21a8 8 0 0 1 16 0"/></svg>
)
const IconMail = () => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M4 6h16v12H4z"/><path d="m4 8 8 6 8-6"/></svg>
)
const IconLock = () => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><rect x="5" y="11" width="14" height="10" rx="2"/><path d="M8 11V7a4 4 0 0 1 8 0v4"/></svg>
)
const IconLeadership = () => (<span className="icon-circle" aria-hidden>💼</span>)
const IconService = () => (<span className="icon-circle" aria-hidden>🐾</span>)
const IconCash = () => (<span className="icon-circle" aria-hidden>💰</span>)
const IconArrowRight = () => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M5 12h12"/><path d="m12 5 7 7-7 7"/></svg>
)

const MascotPopDog = ({mood='neutral'}) => {
  const label = mood==='celebrate' ? '🎉' : mood==='think' ? '🤔' : '🐶'
  return (
    <div className={`mascot ${mood==='celebrate'?'animate':''}`} aria-label={`PopDog ${mood}`}
         style={{backgroundImage:`url('./assets/popdog.svg')`, backgroundSize:'cover', backgroundPosition:'center'}}>
      <span aria-hidden>{label}</span>
    </div>
  )
}

function BottomNav() {
  const linkClass = ({ isActive }) => `item ${isActive ? 'active' : ''}`
  return (
    <nav className="bottom-nav">
      <NavLink className={linkClass} to="/"> <IconHome/> Início </NavLink>
      <NavLink className={linkClass} to="/trilhas"> <IconTrails/> Trilhas </NavLink>
      <NavLink className={linkClass} to="/ranking"> <IconRank/> Ranking </NavLink>
      <NavLink className={linkClass} to="/perfil"> <IconUser/> Perfil </NavLink>
    </nav>
  )
}

const getSession = () => {
  try { return JSON.parse(localStorage.getItem('pa_user')||'null') } catch { return null }
}
const saveSession = (data) => {
  const current = getSession()||{}
  localStorage.setItem('pa_user', JSON.stringify({ ...current, ...data, logged: true }))
}
const clearSession = () => localStorage.removeItem('pa_user')
function RequireAuth({children}){
  const s = getSession()
  if(!s?.logged) return <Navigate to="/login" replace />
  return children
}

function Login() {
  const navigate = useNavigate()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const canProceed = email && password
  const onLogin = () => {
    const name = (email?.split('@')[0]||'Convidado')
    saveSession({ email, name })
    navigate('/selecionar')
  }
  return (
    <div className="login-page">
      <div className="login-card card">
        <div className="login-logo" aria-label="Rede Pop Pet Center"></div>
        <div style={{display:'flex', alignItems:'center', gap:8, margin:'8px 0 6px'}}>
          <div className="subtitle">Bem-vindo! Faça login para continuar</div>
        </div>
        <div style={{height:12}}/>
        <div className="input-wrap" style={{marginTop:8}}>
          <span className="input-icon"><IconMail/></span>
          <input className="input" placeholder="Usuário" value={email} onChange={(e)=>setEmail(e.target.value)} />
        </div>
        <div className="input-wrap" style={{marginTop:12}}>
          <span className="input-icon"><IconLock/></span>
          <input type="password" className="input" placeholder="Senha" value={password} onChange={(e)=>setPassword(e.target.value)} />
        </div>
        <div className="forgot-link"><button className="btn btn-link" onClick={()=>alert('Vamos enviar um link de recuperação para seu e-mail.')}>Esqueci minha senha!</button></div>
        <div style={{height:12}}/>
        <button className="btn btn-primary btn-login" disabled={!canProceed} onClick={onLogin}>
          Entrar <IconArrowRight/>
        </button>
        <div className="card-divider"/>
        <button className="btn btn-link" onClick={()=>navigate('/cadastro')}>Alterar empresa</button>
      </div>
    </div>
  )
}

function SelectRole() {
  const navigate = useNavigate()
  const roles = [
    {key:'gerente', label:'Gerente'},
    {key:'funcionario', label:'Funcionário'},
    {key:'caixa', label:'Caixa'}
  ]
  const choose = (role) => { saveSession({ role }); navigate('/') }
  return (
    <div className="page container">
      <h2 className="title">Selecione seu perfil</h2>
      <div className="grid" style={{gridTemplateColumns:'repeat(3,1fr)'}}>
        {roles.map(r=> (
          <div key={r.key} className="card" style={{textAlign:'center'}}>
            <div className="mascot" style={{width:70,height:70}}>🐾</div>
            <div className="title" style={{fontSize:16}}>{r.label}</div>
            <button className="btn btn-primary" onClick={()=>choose(r.key)}>Entrar como {r.label}</button>
          </div>
        ))}
      </div>
      <BottomNav/>
    </div>
  )
}

function Dashboard() {
  const navigate = useNavigate()
  const s = getSession()||{ name:'Aluno', role:'funcionario' }
  const userName = s.name||'Aluno'
  const role = s.role||'funcionario'
  const xp = 1250
  const level = 2
  const progressPct = 25
  const nextLessonsByRole = {
    gerente: [ {icon:<IconLeadership/>, label:'Liderança'}, {icon:<span className="icon-circle">📦</span>, label:'Gestão de Estoque'}, {icon:<span className="icon-circle">📊</span>, label:'Metas'} ],
    funcionario: [ {icon:<IconService/>, label:'Atendimento'}, {icon:<span className="icon-circle">🛒</span>, label:'Vendas'}, {icon:<span className="icon-circle">🐶</span>, label:'Produtos Pet'} ],
    caixa: [ {icon:<IconCash/>, label:'PDV'}, {icon:<span className="icon-circle">🧮</span>, label:'Fechamento'}, {icon:<span className="icon-circle">🤝</span>, label:'Relacionamento'} ],
  }
  const next = nextLessonsByRole[role]||nextLessonsByRole.funcionario
  return (
    <div className="page container dashboard">
      <div className="grid" style={{gridTemplateColumns:'1.2fr .8fr'}}>
        <div className="card">
          <div className="title">Olá, {userName} 👋</div>
          {/* Mascote fixo no layout */}
          <p className="subtitle">XP total: {xp} • Nível: {level}</p>
          <div className="progress"><div className="bar" style={{width:`${progressPct}%`}}/></div>
          <div style={{height:12}}/>

          <div className="subtitle">Aulas ativas</div>
          <div className="grid" style={{gridTemplateColumns:'repeat(3,1fr)'}}>
            {next.map(n => (
              <button key={n.label} className="card lesson-card" onClick={()=>navigate('/aula')}>
                {n.icon}
                <div className="title" style={{fontSize:16,marginTop:6}}>{n.label}</div>
              </button>
            ))}
          </div>

          <div style={{height:12}}/>
          <div className="subtitle">Conquistas</div>
          <div className="grid" style={{gridTemplateColumns:'repeat(3,1fr)'}}>
            <div className="badge pulse"><span className="icon-circle">🥇</span> Medalha Ouro</div>
            <div className="badge"><span className="icon-circle">🔥</span> Série 7 dias</div>
            <div className="badge"><span className="icon-circle">⭐</span> Destaque</div>
          </div>

          <div style={{height:12}}/>
          <div className="badge mission"><span className="icon-circle">🎯</span> Missão do dia: Ganhe 10 XP hoje</div>

          <div style={{height:12}}/>
          <button className="btn btn-primary" style={{marginTop:12}} onClick={()=>navigate('/trilhas')}>Ir para trilhas</button>
        </div>

        <div className="card">
          <div className="title">Ranking da semana</div>
          <div className="leaderboard">
            <div className="row"><span className="pos gold">1</span> Pedro — 320</div>
            <div className="row"><span className="pos silver">2</span> Maria — 310</div>
            <div className="row"><span className="pos bronze">3</span> João — 300</div>
            <div className="row highlight"><span className="pos">Você</span> {userName} — {xp}</div>
          </div>
          <button className="btn btn-secondary" style={{marginTop:8}} onClick={()=>navigate('/ranking')}>Ver ranking completo</button>
        </div>
      </div>

      
    </div>
  )
}

function IconHeadset(){
  return <Headphones size={24} />
}
function IconBag(){
  return <ShoppingBag size={24} />
}
function IconPaw(){
  return <PawPrint size={24} />
}
function Trilhas() {
  const navigate = useNavigate()
  const s = getSession()||{ role:'funcionario' }
  const role = s.role||'funcionario'
  const trilhasPorPapel = {
    gerente: ['Liderança','Gestão de Loja','Estoque'],
    funcionario: ['Atendimento','Vendas','Produtos Pet'],
    caixa: ['PDV','Fechamento','Relacionamento']
  }
  const nodes = trilhasPorPapel[role]||trilhasPorPapel.funcionario
  return (
    <TrailsSection nodes={nodes} navigate={navigate} />
  )
}

function AulaQuiz() {
  const navigate = useNavigate()
  const [answer,setAnswer] = useState(null)
  const [confetti,setConfetti] = useState(false)
  const [thinking,setThinking] = useState(false)
  const confirm = () => {
    const ok = answer === 'Ouvir com atenção'
    if (ok) {
      setConfetti(true)
      setTimeout(()=> setConfetti(false), 1200)
      alert('Você acertou! +10 pontos')
      navigate('/trilhas')
    } else {
      setThinking(true)
      setTimeout(()=> setThinking(false), 1200)
      alert('Tente novamente! Dica: escute com atenção e ofereça ajuda.')
    }
  }
  return (
    <div className="page container" style={{maxWidth:680}}>
      <div className={`confetti ${confetti?'show':''}`} aria-hidden></div>
      <div className="card" style={{textAlign:'center'}}>
        <MascotPopDog mood={confetti ? 'celebrate' : thinking ? 'think' : 'neutral'}/>
        <div className="title">Pergunta 1</div>
        <p className="subtitle">O que fazer quando o cliente reclama?</p>
        {['Ouvir com atenção','Interromper','Ignorar','Fazer cara séria'].map(opt=> (
          <label key={opt} style={{display:'block',margin:'8px 0'}}>
            <input type="radio" name="q1" onChange={()=>setAnswer(opt)} /> {opt}
          </label>
        ))}
        <button className="btn btn-primary" style={{marginTop:8}} onClick={confirm}>Confirmar</button>
        <p className="subtitle" style={{marginTop:6}}>XP: 1250 • Nível: 2</p>
        <button className="btn btn-secondary" style={{marginTop:8}} onClick={()=>navigate('/aula')}>Próximo desafio</button>
      </div>
    </div>
  )
}

function Ranking() {
  const [showModal, setShowModal] = useState(false)
  const s = getSession()||{ name:'Você' }
  const userName = s.name || 'Você'
  
  const data = [
    { pos: 1, name: 'Pedro', score: 320, level: 5, title: 'Mestre do Atendimento', avatar: '🥇' },
    { pos: 2, name: 'Maria', score: 310, level: 5, title: 'Expert em Vendas', avatar: '🥈' },
    { pos: 3, name: 'João', score: 300, level: 4, title: 'Pro Produtos Pet', avatar: '🥉' },
    { pos: 4, name: userName, score: 295, level: 4, title: 'Atendente Pro', avatar: '⭐' },
    { pos: 5, name: 'Alice', score: 280, level: 3, title: 'Consultor de Loja', avatar: '⭐' },
    { pos: 6, name: 'Bruno', score: 270, level: 3, title: 'Especialista', avatar: '⭐' },
    { pos: 7, name: 'Carla', score: 260, level: 3, title: 'Atendimento', avatar: '⭐' },
    { pos: 8, name: 'Daniel', score: 250, level: 2, title: 'Iniciante', avatar: '⭐' },
    { pos: 9, name: 'Elisa', score: 240, level: 2, title: 'Iniciante', avatar: '⭐' },
    { pos: 10, name: 'Felipe', score: 230, level: 2, title: 'Iniciante', avatar: '⭐' }
  ]
  const you = data.find(d => d.name === userName) || data[3]
  const target = data.find(d => d.pos === (you.pos - 1))
  const needed = Math.max(0, (target?.score || 0) - (you?.score || 0))
  const progressPct = target ? Math.min(100, Math.round((you.score / target.score) * 100)) : 100
  
  return (
    <div className="page container ranking-page">
      <h2 className="title">Ranking</h2>
      <div className="ranking-layout">
        <div className="podium">
          {data.slice(0,3).map((d,i)=> (
             <div key={d.name} className={`podium-card ${i===0?'gold': i===1?'silver':'bronze'} fade-in`}>
+              <div className={`pos-badge ${i===0?'gold': i===1?'silver':'bronze'}`}>{d.pos}</div>
               <div className="podium-top">
                 <span className="trophy">🏆</span>
                 <span className="medal">{d.avatar}</span>
               </div>
               <div className="podium-body">
                 <div className="avatar">{d.avatar}</div>
                 <div className="name">{d.name}</div>
                 <div className="score">{d.score} XP</div>
                 <div className="level">Nível {d.level} — {d.title}</div>
               </div>
             </div>
           ))}
        </div>
  
        <div className="ranking-list">
          {data.slice(3).map(d => (
            <div key={d.name} className={`list-item ${d.name===userName?'highlight':''} slide-up`}>
              <div className="avatar small">{d.avatar}</div>
              <div className="details">
                <div className="name-row">
                  <span className="pos">#{d.pos}</span>
                  <span className="name">{d.name}</span>
                </div>
                <div className="level">Nível {d.level} — {d.title}</div>
              </div>
              <div className="score">{d.score} XP</div>
            </div>
          ))}
        </div>
      </div>
  
      <div className="user-progress card">
        <div className="title" style={{fontSize:18}}>Sua posição</div>
        <p className="subtitle">Você está em #{you.pos}. Faltam <b>{needed} XP</b> para passar o #{target?.pos} ({target?.name}).</p>
        <div className="progress-mini"><div className="bar" style={{width: `${progressPct}%`}}/></div>
        <button className="btn btn-secondary" style={{marginTop:12}} onClick={()=>setShowModal(true)}>Ver desempenho detalhado</button>
      </div>
  
      <div className="trail-cta"><span className="bounce">🐶</span> Continue jogando e suba no ranking!</div>
  
      {showModal && (
        <div className="modal" role="dialog" aria-modal="true" aria-label="Desempenho detalhado">
          <div className="modal-content">
            <div className="title">Desempenho detalhado</div>
            <p className="subtitle">Aqui você verá estatísticas de XP por trilha, acertos em quizzes e evolução semanal.</p>
            <div className="grid" style={{gridTemplateColumns:'repeat(2,1fr)'}}>
              <div className="card"><div className="title" style={{fontSize:16}}>XP por Trilhas</div><div className="progress-mini"><div className="bar" style={{width:'68%'}}/></div></div>
              <div className="card"><div className="title" style={{fontSize:16}}>Taxa de acerto</div><div className="progress-mini"><div className="bar" style={{width:'82%'}}/></div></div>
            </div>
            <button className="btn btn-primary" style={{marginTop:12}} onClick={()=>setShowModal(false)}>Fechar</button>
          </div>
        </div>
      )}
    </div>
  )
}

function Perfil() {
  const navigate = useNavigate()
  const s = getSession()||{ name:'Aluno', role:'funcionario' }
  const logout = () => { clearSession(); navigate('/login') }
  return (
    <div className="page container" style={{maxWidth:480}}>
      <div className="card" style={{textAlign:'center'}}>
        <div className="mascot">🙂</div>
        <div className="title">{s.name||'Aluno'}</div>
        <p className="subtitle">{(s.role||'Funcionário').toUpperCase()} • 1250 pontos • 2º nível</p>
        <button className="btn btn-secondary" onClick={()=>navigate('/perfil/edit')}>Editar Perfil</button>
        <div style={{height:8}}/>
        <button className="btn btn-primary" onClick={logout}>Sair</button>
      </div>
    </div>
  )
}

function PerfilEdit() {
  const navigate = useNavigate()
  const [name,setName] = useState('Maria')
  return (
    <div className="page container" style={{maxWidth:480}}>
      <div className="card">
        <div className="title">Editar Perfil</div>
        <label className="subtitle">Nome</label>
        <input className="input" value={name} onChange={(e)=>setName(e.target.value)} />
        <div style={{height:10}}/>
        <button className="btn btn-primary" onClick={()=>navigate('/perfil')}>Salvar</button>
        <div style={{height:8}}/>
        <button className="btn btn-secondary" onClick={()=>navigate('/perfil')}>Cancelar</button>
      </div>
    </div>
  )
}

function Admin() {
  const navigate = useNavigate()
  const s = getSession()
  const allowed = s?.role === 'gerente'
  return (
    <div className="page container">
      <h2 className="title">Painel Administrativo</h2>
      {!allowed ? (
        <div className="card">
          <p className="subtitle">Acesso restrito: apenas Gerente pode acessar.</p>
          <button className="btn btn-secondary" onClick={()=>navigate('/')}>Voltar</button>
        </div>
      ) : (
        <div className="grid" style={{gridTemplateColumns:'repeat(3,1fr)'}}>
          <div className="card">
            <div className="title" style={{fontSize:16}}>Criar trilha</div>
            <button className="btn btn-primary" style={{marginTop:8}} onClick={()=>navigate('/trilhas')}>Nova trilha</button>
          </div>
          <div className="card">
            <div className="title" style={{fontSize:16}}>Gerar relatório</div>
            <button className="btn btn-secondary" style={{marginTop:8}} onClick={()=>navigate('/admin')}>Exportar</button>
          </div>
          <div className="card">
            <div className="title" style={{fontSize:16}}>Lançar módulo</div>
            <button className="btn btn-primary" style={{marginTop:8}} onClick={()=>navigate('/admin')}>Publicar</button>
          </div>
        </div>
      )}
    </div>
  )
}

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<RequireAuth><Layout><Dashboard/></Layout></RequireAuth>} />
        <Route path="/login" element={<Login/>} />
        <Route path="/cadastro" element={<Cadastro/>} />
        <Route path="/selecionar" element={<RequireAuth><Layout><SelectRole/></Layout></RequireAuth>} />
        <Route path="/trilhas" element={<RequireAuth><Layout><Trilhas/></Layout></RequireAuth>} />
        <Route path="/aula" element={<RequireAuth><Layout><AulaQuiz/></Layout></RequireAuth>} />
        <Route path="/ranking" element={<RequireAuth><Layout><Ranking/></Layout></RequireAuth>} />
        <Route path="/perfil" element={<RequireAuth><Layout><Perfil/></Layout></RequireAuth>} />
        <Route path="/perfil/edit" element={<RequireAuth><Layout><PerfilEdit/></Layout></RequireAuth>} />
        <Route path="/admin" element={<RequireAuth><Layout><Admin/></Layout></RequireAuth>} />
        <Route path="/loja" element={<RequireAuth><Layout><Loja/></Layout></RequireAuth>} />
        <Route path="/config" element={<RequireAuth><Layout><Config/></Layout></RequireAuth>} />
      </Routes>
    </BrowserRouter>
  )
}

function Cadastro(){
  const navigate = useNavigate()
  const [name,setName] = useState('')
  const [email,setEmail] = useState('')
  const [password,setPassword] = useState('')
  const canCreate = name && email && password
  const create = () => { saveSession({ name, email }); navigate('/selecionar') }
  return (
    <div className="page auth">
      <div className="card" style={{textAlign:'center', maxWidth:500, margin:'0 auto'}}>
        <div className="mascot" aria-hidden>🐶</div>
        <div className="title">Criar conta</div>
        <div className="input-wrap" style={{marginTop:8}}>
          <input className="input" placeholder="Nome" value={name} onChange={(e)=>setName(e.target.value)} />
        </div>
        <div className="input-wrap" style={{marginTop:8}}>
          <span className="input-icon"><IconMail/></span>
          <input className="input" placeholder="Email" value={email} onChange={(e)=>setEmail(e.target.value)} />
        </div>
        <div className="input-wrap" style={{marginTop:8}}>
          <span className="input-icon"><IconLock/></span>
          <input type="password" className="input" placeholder="Senha" value={password} onChange={(e)=>setPassword(e.target.value)} />
        </div>
        <button className="btn btn-primary" style={{marginTop:10}} disabled={!canCreate} onClick={create}>Criar conta</button>
        <div style={{height:8}}/>
        <button className="btn btn-secondary" onClick={()=>navigate('/login')}>Já tenho conta</button>
      </div>
    </div>
  )
}

const IconStore = () => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M3 7h18"/><path d="M5 7v12h14V7"/><path d="M9 11h6"/></svg>
)
const IconSettings = () => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6Z"/><path d="M19.4 15a7.8 7.8 0 0 0 .1-6l2.1-2.1-2.8-2.8-2.1 2.1a7.8 7.8 0 0 0-6-.1L8.6 1.9 5.8 4.7l2.1 2.1a7.8 7.8 0 0 0-.1 6L5.8 15.9l2.8 2.8 2.1-2.1a7.8 7.8 0 0 0 6 .1l2.1 2.1 2.8-2.8-2.1-2.1Z"/></svg>
)
function Sidebar(){
  const linkClass = ({ isActive }) => `menu-item ${isActive ? 'active' : ''}`
  return (
    <aside className="sidebar">
      <div className="brand">PA</div>
      <nav className="menu">
        <NavLink className={linkClass} to="/"> <IconHome/> <span>Início</span> </NavLink>
        <NavLink className={linkClass} to="/trilhas"> <IconTrails/> <span>Trilhas</span> </NavLink>
        <NavLink className={linkClass} to="/ranking"> <IconRank/> <span>Ranking</span> </NavLink>
        <NavLink className={linkClass} to="/loja"> <IconStore/> <span>Loja</span> </NavLink>
        <NavLink className={linkClass} to="/perfil"> <IconUser/> <span>Perfil</span> </NavLink>
        <NavLink className={linkClass} to="/config"> <IconSettings/> <span>Config</span> </NavLink>
      </nav>
    </aside>
  )
}
function Layout({children}){
  const tip = "Mantenha sua sequência para ganhar XP!"
  return (
    <div className="app-shell">
      <Sidebar/>
      <main className="main">
        {children}
      </main>
      <div className="mascot-tip">
        <div className="bubble">{tip}</div>
        <MascotPopDog mood="neutral"/>
      </div>
    </div>
  )
}

function Loja(){
  const itens = [
    {id:1, nome:'Badge Ouro', precoXP:200, emoji:'🏅'},
    {id:2, nome:'Camiseta Pop', precoXP:500, emoji:'👕'},
    {id:3, nome:'Caneca Pop', precoXP:350, emoji:'☕'},
  ]
  return (
    <div className="page container">
      <h2 className="title">Loja de Recompensas</h2>
      <div className="grid" style={{gridTemplateColumns:'repeat(3,1fr)'}}>
        {itens.map(item=> (
          <div key={item.id} className="card" style={{textAlign:'center'}}>
            <div className="icon-circle" style={{width:52, height:52, fontSize:24}} aria-hidden>{item.emoji}</div>
            <div className="subtitle" style={{fontWeight:700}}>{item.nome}</div>
            <button className="btn btn-primary" style={{marginTop:8}}>Trocar por {item.precoXP} XP</button>
          </div>
        ))}
      </div>
    </div>
  )
}
function Config(){
  const navigate = useNavigate()
  return (
    <div className="page container">
      <h2 className="title">Configurações</h2>
      <div className="card">
        <div style={{display:'flex', alignItems:'center', justifyContent:'space-between'}}>
          <div>
            <div className="title" style={{fontSize:16}}>Notificações internas</div>
            <div className="subtitle">Receber alertas como "Você ganhou 10 XP!"</div>
          </div>
          <button className="btn btn-secondary">Ativar</button>
        </div>
        <div style={{height:12}}/>
        <div style={{display:'flex', alignItems:'center', justifyContent:'space-between'}}>
          <div>
            <div className="title" style={{fontSize:16}}>Sons e animações leves</div>
            <div className="subtitle">Feedbacks visuais e sonoros</div>
          </div>
          <button className="btn btn-secondary">Ativar</button>
        </div>
        <div style={{height:12}}/>
        <button className="btn btn-primary" onClick={()=>navigate('/')}>Salvar alterações</button>
      </div>
    </div>
  )
}
