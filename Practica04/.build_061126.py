# -*- coding: utf-8 -*-
import re,json,pathlib,collections,html
src=pathlib.Path('backups/061126.sql')
lines=src.read_text(encoding='utf-8-sig').splitlines()
tables={};triggers=[];views=[];procedures=[];functions=[];rows=collections.Counter();table_lines={}
i=0
while i<len(lines):
 line=lines[i]
 m=re.match(r'CREATE TABLE `([^`]+)` \(',line)
 if m:
  name=m.group(1);table_lines[name]=i+1;cols=[];body=[];i+=1
  while i<len(lines) and ') ENGINE=' not in lines[i]:
   body.append(lines[i]);c=re.match(r'\s*`([^`]+)`\s+(.+?)(?:,)?\s*$',lines[i])
   if c:cols.append({'name':c.group(1),'decl':c.group(2).rstrip(',')})
   i+=1
  eng=re.search(r'\) ENGINE=(\w+)(.*?);',lines[i]) if i<len(lines) else None
  tables[name]={'columns':cols,'body':'\n'.join(body),'engine':eng.group(1) if eng else 'InnoDB'};i+=1;continue
 tm=re.search(r'TRIGGER `([^`]+)` (AFTER|BEFORE) (INSERT|UPDATE|DELETE) ON `([^`]+)`',line)
 if tm:
  n,timing,event,table=tm.groups();b=[];j=i
  while j<len(lines):
   b.append(lines[j])
   if lines[j].rstrip().endswith(';;'):break
   j+=1
  body=' '.join(b);fm=re.search(r'INSERT INTO `?tb_logs`?\s*\(([^)]+)\)',body,re.I)
  triggers.append({'name':n,'timing':timing,'event':event,'table':table,'fields':[x.strip().strip('` ') for x in fm.group(1).split(',')] if fm else []});i+=1;continue
 vm=re.search(r'CREATE VIEW `([^`]+)`',line)
 if vm:views.append(vm.group(1))
 pm=re.search(r'CREATE(?:\s+DEFINER=.*?)?\s+PROCEDURE\s+`([^`]+)`',line,re.I)
 if pm:procedures.append(pm.group(1))
 fm=re.search(r'CREATE(?:\s+DEFINER=.*?)?\s+FUNCTION\s+`([^`]+)`',line,re.I)
 if fm:functions.append(fm.group(1))
 if line.startswith('-- Dumping data for table '):
  mt=re.search(r'`([^`]+)`',line);table=mt.group(1) if mt else '';j=i+1
  while j<len(lines) and not lines[j].startswith('UNLOCK TABLES;'):
   if lines[j].startswith('INSERT INTO `') and ' VALUES' in lines[j]:
    text=lines[j].split('VALUES',1)[1];dep=0;q=None;esc=False;n=0
    for ch in text:
     if q:
      if esc:esc=False
      elif ch=='\\':esc=True
      elif ch==q:q=None
     elif ch in "'\"`":q=ch
     elif ch=='(':n+=dep==0;dep+=1
     elif ch==')':dep=max(0,dep-1)
    rows[table]+=n
   j+=1
 i+=1
full='\n'.join(lines)
def signature(kind,name):
 token=kind+' `'+name+'`(';at=full.find(token)
 if at<0:return ''
 p=at+len(token)-1;dep=0;q=None;esc=False;e=p
 while e<len(full):
  c=full[e]
  if q:
   if esc:esc=False
   elif c=='\\':esc=True
   elif c==q:q=None
  elif c in "'\"`":q=c
  elif c=='(':dep+=1
  elif c==')':
   dep-=1
   if dep==0:break
  e+=1
 result='('+full[p+1:e].strip()+')'
 if kind=='FUNCTION':result+=' '+full[e+1:e+100].split('BEGIN',1)[0].strip()
 return result
views_data=[]
for line in lines:
 m=re.search(r'VIEW `([^`]+)` AS (.*?)(?:\*/;|$)',line,re.I)
 if m and m.group(1) in views:
  definition=m.group(2).strip();bases=sorted(set(re.findall(r'\b(?:FROM|JOIN)\s+`([^`]+)`',definition,re.I)))
  views_data.append({'name':m.group(1),'kind':'Funcional' if m.group(1)=='vw_total_products_by_category' else 'Trazabilidad','bases':bases,'sql':definition})
domains={
 'Cuentas y experiencia':['tb_users','tb_people','tb_user_addresses','tbd_address_components','tb_carts','tbd_cart_items','tbd_user_payment_methods','tbd_users_wishlist_products'],
 'Catálogo':['tb_products','tbc_categories','tbd_products_categories','tbd_products_users_providers'],
 'Pedidos y cumplimiento':['tb_orders','tb_buyer_orders','tbd_order_items','tb_order_cancellations','tbd_cancellation_items','tb_shipments','tb_returns','tbd_return_items'],
 'Pagos y auditoría':['tb_payments','tb_payment_methods','tbc_payment_methods_types','tb_payment_transaction','tb_refunds','tb_logs']}
domainof={t:d for d,ts in domains.items() for t in ts}
business={
 'tb_users':'Identidad de cuenta, credenciales, rol y actividad de compradores/vendedores.','tb_people':'Información personal complementaria de la cuenta.','tb_products':'Catálogo comercial con SKU, precio, inventario y publicación.',
 'tb_orders':'Cabecera de compra del usuario y ciclo de vida del pedido.','tb_buyer_orders':'Pedido dividido por vendedor con importes y estado de surtido.','tb_order_cancellations':'Solicitud y resolución de cancelaciones.','tbd_cancellation_items':'Partidas afectadas por una cancelación.',
 'tbd_order_items':'Artículos comprados, cantidad, precio unitario y total de línea.','tb_carts':'Carrito asociado a una cuenta compradora.','tbd_cart_items':'Productos y cantidades del carrito.','tbc_categories':'Taxonomía jerárquica para clasificar productos.',
 'tbd_products_categories':'Asociación de productos y categorías.','tbd_products_users_providers':'Asociación de vendedores/proveedores y productos.','tb_user_addresses':'Dirección del usuario desglosada en componentes.','tbd_address_components':'Componentes extensibles tipo/valor de una dirección.',
 'tb_payment_methods':'Catálogo de medios de pago disponibles.','tbc_payment_methods_types':'Catálogo de tipos de medio de pago.','tb_payments':'Cobro de una orden con importe, moneda, método y estado.','tb_payment_transaction':'Intentos/transacciones individuales de un pago.',
 'tbd_user_payment_methods':'Medios de pago guardados por usuario.','tb_refunds':'Reembolsos originados por pago, devolución o cancelación.','tb_returns':'Solicitud y revisión de devoluciones.','tbd_return_items':'Detalle de condición, disposición y reembolso de un artículo devuelto.',
 'tb_shipments':'Envíos por suborden con tracking y fechas.','tbd_users_wishlist_products':'Productos guardados por usuarios en su lista de deseos.','tb_logs':'Bitácora de auditoría común a las tablas operativas.'}
technical={
 'tb_logs':'Destino InnoDB de los triggers; ID AUTO_INCREMENT y operation_date DEFAULT CURRENT_TIMESTAMP.','tb_orders':'Entidad transaccional para partidas, pagos, cancelaciones y devoluciones; el dump incluye triggers de auditoría.',
 'tb_buyer_orders':'Suborden relacionada a pedido y vendedor; total_amount GENERATED STORED.','tb_carts':'Cabecera InnoDB con unicidad de user_ID (máximo un carrito por usuario).','tb_people':'Extensión de tb_users con FK única (1:1).',
 'tbd_order_items':'PK compuesta y FK identificante al pedido; line_total GENERATED STORED.','tbd_products_categories':'Tabla puente N:M con PK compuesta por las FKs.','tbd_products_users_providers':'Tabla puente N:M con PK compuesta por las FKs.',
 'tbc_categories':'Autorrelación sup_id_category para padre/subcategoría.','tb_user_addresses':'user_id no tiene FK declarada en el DDL.','tbd_address_components':'user_address_id no tiene FK declarada en el DDL.',
 'tbd_cart_items':'cart_id y product_id no tienen FKs declaradas en el DDL.','tbd_users_wishlist_products':'PK compuesta, pero sin FKs declaradas.','tb_payment_transaction':'Registro técnico de transacciones separado de tb_payments.',
 'tb_shipments':'Relación FK a suborden del vendedor y datos de tracking.'}
for n in tables:technical.setdefault(n,'Tabla física InnoDB operacional o de referencia; sus relaciones son las FKs definidas en el DDL.')

fkpat=re.compile(r'CONSTRAINT `([^`]+)`\s+FOREIGN KEY\s*\(([^)]+)\)\s+REFERENCES\s+`([^`]+)`\s*\(([^)]+)\)\s*(?:ON DELETE\s+(CASCADE|RESTRICT|SET\s+NULL|NO ACTION))?\s*(?:ON UPDATE\s+(CASCADE|RESTRICT|SET\s+NULL|NO ACTION))?',re.I|re.S)
rels=[];colrefs=collections.defaultdict(list)
def pks(t):
 m=re.search(r'PRIMARY KEY\s*\(([^)]+)\)',t['body'],re.I);return [z.strip().strip('`') for z in m.group(1).split(',')] if m else []
def uniques(t):return [set(z.strip().strip('`') for z in m.group(1).split(',')) for m in re.finditer(r'UNIQUE(?: KEY| INDEX)\s+`[^`]+`\s*\(([^)]+)\)',t['body'],re.I)]
for child,t in tables.items():
 cols={c['name']:c['decl'] for c in t['columns']}
 for m in fkpat.finditer(t['body']):
  nm,rawc,parent,rawp,dele,upd=m.groups();cc=[x.strip().strip('`') for x in rawc.split(',')];pp=[x.strip().strip('`') for x in rawp.split(',')]
  for c,p in zip(cc,pp):colrefs[(child,c)].append(parent+'.'+p)
  nullable=any(not re.search(r'\bNOT\s+NULL\b',cols.get(c,''),re.I) for c in cc);unique=any(set(cc)==u for u in uniques(t));ident=set(cc).issubset(set(pks(t)))
  rels.append({'name':nm,'parent':parent,'child':child,'cc':cc,'pp':pp,'delete':(dele or 'RESTRICT').upper(),'update':(upd or 'RESTRICT').upper(),'optional':nullable,'one':unique,'identifying':ident})
logcols={c['name'] for c in tables['tb_logs']['columns']};logfields=set(x for tr in triggers for x in tr['fields'])
invalid=sorted(logfields-logcols)
spderived={('tb_products','current_stock'):'sp_attend_order resta cantidad al stock.',('tb_payment_transaction','transaction_reference'):'sp_authorize_payment genera una referencia con UUID().',('tb_shipments','tracking_number'):'sp_deliver_order calcula la guía con CONCAT/LPAD.',('tb_shipments','estimated_delivery_date'):'sp_deliver_order calcula NOW()+3 días.',('tb_users','password'):'sp_register_new_user persiste MD5(p_password).'}
generated=set()
tabledata=[]
for name,t in tables.items():
 pk=pks(t);uniq=uniques(t);constraints=[x.strip().rstrip(',') for x in t['body'].splitlines() if re.match(r'\s*(?:PRIMARY KEY|UNIQUE KEY|KEY|CONSTRAINT|CHECK)',x,re.I)];cols=[]
 for c in t['columns']:
  dec=c['decl'];typm=re.match(r"(enum\(.*?\)|set\(.*?\)|[a-zA-Z]+(?:\([^)]*\))?)",dec,re.I);typ=(typm.group(1) if typm else dec.split()[0]);typ='enum' if typ.lower().startswith('enum(') else ('set' if typ.lower().startswith('set(') else typ);lo=typ.lower();nm=c['name'];low=nm.lower()
  keys=[]
  if nm in pk:keys.append('PK')
  if (name,nm) in colrefs:keys.append('FK → '+', '.join(colrefs[(name,nm)]))
  if any({nm}==u for u in uniq):keys.append('UK')
  multi=lo.startswith(('json','set'));quantity='Multivalorado' if multi else 'Monovalorado';comp='Compuesto' if multi or low=='operation_description' else 'Simple'
  if low=='id' or low.endswith('_id') or low.endswith('id') or re.search(r'(status|state|role|gender|condition|disposition|ownership|operation|reason|type|code|currency|sku|email|nick|tracking|reference|country|postal|phone|password|name|description|url)',low) or lo.startswith(('char','varchar','text','enum','set')):nature='Cualitativa (Ordinal: estado)' if any(x in low for x in ('status','state','role','condition','disposition')) else 'Cualitativa (Nominal)'
  elif lo.startswith(('bit(1)','bool','boolean')):nature='Cualitativa (Nominal: bandera)'
  elif lo.startswith(('tinyint','smallint','mediumint','int','bigint')):nature='Cuantitativa (Discreta)'
  elif lo.startswith(('decimal','numeric','float','double')):nature='Cuantitativa (Continua)'
  elif lo.startswith(('date','time','year')):nature='Cuantitativa (Continua: temporal)'
  else:nature='Cualitativa (Nominal)'
  if 'GENERATED ALWAYS' in dec.upper():origin='Derivado y Almacenado (GENERATED)'
  elif (name,nm) in spderived:origin='Derivado y Almacenado (SP)'
  elif name=='tb_logs' and nm in logfields:origin='Derivado y Almacenado (Trigger)'
  else:origin='Almacenado'
  null='NOT NULL' if re.search(r'\bNOT\s+NULL\b',dec,re.I) else 'Admite NULL';default=re.search(r'\bDEFAULT\s+(.+?)(?:\s+ON UPDATE\b|\s+COMMENT\b|$)',dec,re.I)
  if 'AUTO_INCREMENT' in dec.upper():ins='Puede omitirse: AUTO_INCREMENT genera el valor.'
  elif 'GENERATED ALWAYS' in dec.upper():ins='No se envía: MySQL calcula la columna GENERATED.'
  elif default:ins='Puede omitirse: aplica DEFAULT '+default.group(1).strip()+'.'
  elif null=='Admite NULL':ins='Puede omitirse; en MySQL se usa NULL implícito si no hay DEFAULT.'
  else:ins='Mandatorio: NOT NULL sin DEFAULT, AUTO_INCREMENT o cálculo automático.'
  dom=lo;enum=re.search(r'\b(enum|set)\((.*?)\)',dec,re.I)
  if enum:dom+='; valores: '+enum.group(2)
  if lo.startswith(('varchar(','char(')):
   q=re.search(r'\((\d+)\)',lo)
   if q:dom+=f'; máximo {q.group(1)} caracteres'
  if lo.startswith(('decimal(','numeric(')):
   q=re.search(r'\((\d+),(\d+)\)',lo)
   if q:
    p,s=map(int,q.groups());mx=10**(p-s)-10**(-s);dom+=f"; rango {'0 a '+str(mx) if 'UNSIGNED' in dec.upper() else '-'+str(mx)+' a '+str(mx)}"
  if lo.startswith(('tinyint','smallint','mediumint','int','bigint')):
   rr={'tinyint':(-128,127,8),'smallint':(-32768,32767,16),'mediumint':(-8388608,8388607,24),'int':(-2147483648,2147483647,32),'bigint':(-9223372036854775808,9223372036854775807,64)};k=next(x for x in rr if lo.startswith(x));a,b,bits=rr[k];dom+=f"; rango {'0 a '+str(2**bits-1) if 'UNSIGNED' in dec.upper() else str(a)+' a '+str(b)}"
  if lo.startswith('bit('):q=re.search(r'bit\((\d+)\)',lo);bits=int(q.group(1)) if q else 1;dom+=f'; rango 0 a {2**bits-1}'
  if lo=='date':dom+='; MySQL DATE 1000-01-01 a 9999-12-31'
  if lo.startswith('datetime'):dom+='; MySQL DATETIME 1000-01-01 00:00:00 a 9999-12-31 23:59:59'
  if lo.startswith('timestamp'):dom+='; MySQL TIMESTAMP UTC 1970-01-01 00:00:01 a 2038-01-19 03:14:07'
  checks=[x.strip().rstrip(',') for x in t['body'].splitlines() if 'CHECK' in x.upper() and re.search(r'`'+re.escape(nm)+r'`',x,re.I)]
  if checks:dom+='; CHECK: '+' '.join(checks)
  expr=re.search(r'GENERATED ALWAYS AS \((.*)\)\s+(VIRTUAL|STORED)',dec,re.I)
  if expr:dom+='; expresión '+expr.group(1)+'; '+expr.group(2).upper()
  det=spderived.get((name,nm),'')
  if det:ins+=' '+det
  cols.append({'name':nm,'sql':dec,'type':typ,'key':' · '.join(keys),'count':quantity,'composition':comp,'nature':nature,'origin':origin,'detail':det,'domain':dom,'null':null,'insert':ins})
 all_tr= [tr for tr in triggers if tr['table']==name]
 weak=any(r['child']==name and r['identifying'] for r in rels)
 tabledata.append({'name':name,'domain':domainof.get(name,'Otros'),'business':business.get(name,'Entidad operativa o de referencia del sistema de comercio.'),'technical':technical.get(name,'Tabla física InnoDB; sus dependencias se limitan a las restricciones declaradas.'),'rows':rows.get(name,0),'line':table_lines.get(name,0),'columns':cols,'constraints':constraints,'triggers':all_tr,'weak':weak,'pk':pk})
view_data=[]
for line in lines:
 m=re.search(r'VIEW `([^`]+)` AS (.*?)(?:\*/;|$)',line,re.I)
 if m and m.group(1) in views:
  sql=m.group(2).strip();view_data.append({'name':m.group(1),'kind':'Funcional' if m.group(1)=='vw_total_products_by_category' else 'Trazabilidad','tables':sorted(set(re.findall(r'\b(?:FROM|JOIN)\s+`([^`]+)`',sql,re.I))),'sql':sql})
def signature(kind,n):
 token=kind+' `'+n+'`(';a=full.find(token)
 if a<0:return ''
 p=a+len(token)-1;dep=0;q=None;esc=False;e=p
 while e<len(full):
  c=full[e]
  if q:
   if esc:esc=False
   elif c=='\\':esc=True
   elif c==q:q=None
  elif c in "'\"`":q=c
  elif c=='(':dep+=1
  elif c==')':
   dep-=1
   if dep==0:break
  e+=1
 result='('+full[p+1:e].strip()+')'
 return result+(' '+full[e+1:e+90].split('BEGIN',1)[0].strip() if kind=='FUNCTION' else '')
metrics={'tables':len(tables),'operational':len(tables)-1,'columns':sum(len(t['columns']) for t in tables.values()),'users':rows.get('tb_users',0),'people':rows.get('tb_people',0),'products':rows.get('tb_products',0),'triggers':len(triggers),'trigger_tables':len(set(t['table'] for t in triggers)),'views':len(views),'traceviews':sum(v.startswith('vw_trazabilidad_') for v in views),'procedures':len(procedures),'functions':len(functions),'fks':len(rels),'totalrows':sum(rows.values()),'events':dict(collections.Counter(t['event'] for t in triggers))}
data={'tables':tabledata,'domains':domains,'rels':rels,'triggers':triggers,'views':view_data,'procedures':procedures,'functions':functions,'procsigs':{n:signature('PROCEDURE',n) for n in procedures},'funcsigs':{n:signature('FUNCTION',n) for n in functions},'logcols':sorted(logcols),'invalid':invalid,'metrics':metrics}
jsondata=json.dumps(data,ensure_ascii=False,separators=(',',':')).replace('</','<\\/')
page=r'''<!doctype html><html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="description" content="Diccionario de datos y modelo EER para Práctica 03, respaldo 061126.sql"><title>Práctica 03 | Diccionario de datos EER</title><style>
:root{color-scheme:light;--ink:#132b3e;--muted:#657b8d;--line:#d6e1e8;--bg:#f2f6f9;--card:#fff;--nav:#10364e;--blue:#16749b;--teal:#167f78;--amber:#926200;--red:#9f343b;--shadow:0 8px 22px #17415b12}*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font:14px/1.48 Inter,Segoe UI,Arial,sans-serif}header{background:linear-gradient(120deg,#10364e,#1e5d72 70%,#167f78);color:white;padding:28px clamp(16px,4vw,60px) 17px}h1{margin:0;font-size:clamp(25px,3.4vw,39px);letter-spacing:-.04em}h2{margin:0 0 10px;font-size:22px;letter-spacing:-.02em}h3{margin:0 0 8px;font-size:16px}.subhead{color:#d9e9f0;margin-top:5px}.metrics{display:grid;grid-template-columns:repeat(auto-fit,minmax(130px,1fr));gap:9px;margin:20px 0}.metric{border:1px solid #ffffff40;background:#ffffff14;border-radius:11px;padding:10px 13px}.metric strong{display:block;font-size:23px}.metric span{font-size:10px;color:#d6e6ec;text-transform:uppercase;letter-spacing:.07em}nav{display:flex;gap:8px;flex-wrap:wrap}.tab{background:#ffffff12;border:1px solid #ffffff40;color:white;border-radius:9px;padding:9px 14px;cursor:pointer;font-weight:650;transition:.2s}.tab:hover{background:#ffffff25;transform:translateY(-1px)}.tab.active{background:white;color:#10364e}main{max-width:1800px;margin:auto;padding:20px clamp(12px,3vw,42px)}.panel{display:none;animation:fade .22s ease}.panel.active{display:block}@keyframes fade{from{opacity:.3;transform:translateY(6px)}to{opacity:1;transform:none}}.notice{background:#fff7e5;border:1px solid #e6c97a;color:#5b4a1d;padding:12px 14px;border-radius:9px;margin:10px 0}.notice.error{background:#fff1ef;border-color:#e3aaa5;color:#762d2c}.lede,.muted{color:var(--muted)}.toolbar{display:flex;gap:8px;flex-wrap:wrap;margin:12px 0}.toolbar input,.toolbar select,.toolbar button{padding:9px 11px;border:1px solid var(--line);border-radius:8px;background:white;color:var(--ink);font:inherit}.toolbar input{flex:1;min-width:230px}.toolbar button{cursor:pointer;background:#e8f1f6}.count{color:var(--muted);font-size:12px;align-self:center}.cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,550px),1fr));gap:11px}.entity,.box{background:var(--card);border:1px solid var(--line);border-radius:11px;box-shadow:var(--shadow);overflow:hidden}.entity>summary{list-style:none;cursor:pointer;padding:12px 14px;display:flex;justify-content:space-between;align-items:center;gap:9px}.entity>summary::-webkit-details-marker{display:none}.entity[open]>summary{border-bottom:1px solid var(--line)}.tablename{font:700 14px Consolas,monospace}.badge,.chip{font-size:10px;padding:3px 8px;border-radius:999px;background:#e8f1f6;color:#31576c;white-space:nowrap}.ctx{display:grid;grid-template-columns:1fr 1fr;gap:10px;padding:11px 14px;background:#f8fafb;font-size:12px}.ctx b{display:block;color:var(--muted);text-transform:uppercase;font-size:10px;letter-spacing:.05em}.meta{font-size:11px;color:var(--muted);padding:7px 14px}.scroll{overflow:auto;max-height:500px;border-top:1px solid var(--line)}table{width:100%;border-collapse:collapse;min-width:1040px;font-size:11px}th{position:sticky;top:0;background:#eaf1f5;z-index:2;text-align:left;color:#42586a;text-transform:uppercase;letter-spacing:.04em;font-size:9px}td,th{padding:8px;border-bottom:1px solid #e5ebef;vertical-align:top}tr:hover td{background:#f7fbfd}.col{font:700 12px Consolas,monospace;color:#164662}.sql{font:10px Consolas,monospace;color:#795b1c;overflow-wrap:anywhere}.keys{font-size:9px;color:#13647a;font-weight:700}.origin{display:inline-block;border-radius:5px;padding:3px 5px;background:#e8f5ec;color:#23603c;font-size:9px}.origin.sp{background:#e9ebff;color:#3a4a9b}.origin.trigger{background:#fff1d6;color:#785300}.origin.generated{background:#e9ebff;color:#3a4a9b}.fold{padding:8px 14px}.fold summary{cursor:pointer;color:var(--blue);font-size:11px}pre{white-space:pre-wrap;overflow-wrap:anywhere;background:#f6f8fa;border:1px solid var(--line);border-radius:7px;padding:9px;font:10px/1.4 Consolas,monospace}.boxes{display:grid;grid-template-columns:repeat(auto-fit,minmax(270px,1fr));gap:9px}.box{padding:11px}.box code{font:600 11px Consolas,monospace;color:#145170}.box p{margin:5px 0 0;font-size:11px;color:var(--muted)}.diagram-tools{display:flex;gap:8px;flex-wrap:wrap;margin:12px 0}.diagram-scroll{overflow:auto;max-height:74vh;border:1px solid var(--line);border-radius:11px;background:#edf3f6}.canvas{position:relative;margin:14px;background-image:radial-gradient(#cbd8e0 1px,transparent 1px);background-size:18px 18px}.edges{position:absolute;inset:0;overflow:visible;pointer-events:none}.edge{fill:none;stroke:#7893a4;stroke-width:1.5;opacity:.65}.edge.ident{stroke:#13778a;stroke-width:2}.edge.focus{stroke:#e28a23;stroke-width:3;opacity:1}.edge-label{font:700 10px Arial;fill:#334e5f;paint-order:stroke;stroke:#edf3f6;stroke-width:4px}.node{position:absolute;width:246px;min-height:112px;background:#fff;border:1.5px solid #8fa7b6;border-radius:8px;box-shadow:0 4px 12px #1b3b4e1a;overflow:hidden;cursor:pointer;z-index:1;transition:.18s}.node.weak{border-style:dashed;border-width:2px}.node:hover,.node.focus{border-color:#e28a23;box-shadow:0 7px 20px #e28a2340;transform:translateY(-2px)}.node.hide{display:none}.node-head{padding:6px 8px;background:#15425d;color:#fff;display:flex;justify-content:space-between;gap:4px;font:700 10px Consolas,monospace}.node-domain{font:9px Arial;color:#d5e6ee}.node-body{padding:5px 8px;font:9px/1.45 Consolas,monospace}.pkline{color:#8c5900}.fkline{color:#126b6e}.node-foot{padding:2px 8px 6px;color:#718494;font-size:9px}.legend{display:flex;gap:12px;flex-wrap:wrap;color:var(--muted);font-size:11px}.footer{margin:20px 0;color:var(--muted);font-size:11px}@media(max-width:680px){.ctx{grid-template-columns:1fr}.metrics{grid-template-columns:repeat(2,1fr)}}
</style></head><body><header><h1>Práctica 03 · Diccionario de Datos y Modelo EER</h1><div class="subhead">Respaldo <code>061126.sql</code> · MySQL / InnoDB · Aplicación estática en un solo archivo</div><div class="metrics" id="metrics"></div><nav><button class="tab active" data-panel="dict">Diccionario de Datos</button><button class="tab" data-panel="eer">Modelo EER</button><button class="tab" data-panel="audit">Matriz de Auditoría / Vistas</button></nav></header><main>
<section class="panel active" id="dict"><div class="notice" id="source-note"></div><div class="toolbar"><input id="search" placeholder="Buscar nombre de tabla o columna…"><select id="domain"><option value="">Todos los dominios</option></select><select id="origin"><option value="">Todos los orígenes</option><option>Almacenado</option><option>Derivado y Almacenado (GENERATED)</option><option>Derivado y Almacenado (SP)</option><option>Derivado y Almacenado (Trigger)</option></select><span class="count" id="count"></span></div><div class="cards" id="tables"></div></section>
<section class="panel" id="eer"><h2>Modelo EER Interactivo</h2><p class="lede">Las cardinalidades y acciones referenciales proceden de las 24 FK declaradas. Pasa el cursor por una relación para ver FK, ON DELETE/UPDATE y participación; clic en una entidad para abrir su ficha.</p><div class="diagram-tools"><input id="ds" placeholder="Filtrar entidades…"><select id="dd"><option value="">Todos los dominios</option></select><button id="zm">−</button><button id="zr">Ajustar</button><button id="zp">+</button><span class="count" id="rc"></span></div><div class="legend"><span>PK</span><span>FK</span><span>1:N / 1:1</span><span>Borde punteado: entidad dependiente</span></div><div class="diagram-scroll" id="diagram-scroll"><div class="canvas" id="canvas"><svg class="edges" id="edges"></svg></div></div><div class="notice">Puentes N:M: tbd_products_categories y tbd_products_users_providers. No hay jerarquía ISA. tbc_categories contiene autorrelación padre/hija. La lista de deseos tiene PK compuesta, pero no FKs declaradas.</div></section>
<section class="panel" id="audit"><h2>Matriz de Auditoría y Vistas</h2><div class="notice error" id="audit-note"></div><div class="box"><h3>Triggers</h3><div class="toolbar"><input id="ts" placeholder="Buscar trigger o tabla…"><select id="te"><option value="">Todos</option><option>INSERT</option><option>UPDATE</option><option>DELETE</option></select><span class="count" id="tc"></span></div><div class="boxes" id="trigger-list"></div></div><div class="box" style="margin-top:12px"><h3>Vistas SQL</h3><div class="toolbar"><input id="vs" placeholder="Buscar vista…"><select id="vk"><option value="">Todas</option><option>Trazabilidad</option><option>Funcional</option></select></div><div class="boxes" id="views"></div></div><div class="box" style="margin-top:12px"><h3>Procedimientos (9) y funciones (2)</h3><div class="boxes" id="routines"></div></div></section>
<div class="footer">Fuente DDL y datos: backups/061126.sql. Volumetría contada desde las sentencias INSERT del respaldo; no es una lectura en vivo del servidor. Vista funcional: vw_total_products_by_category.</div></main><script id="data" type="application/json">__JSON__</script><script>
const D=JSON.parse(document.getElementById('data').textContent),$=id=>document.getElementById(id),esc=x=>String(x??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c])),fmt=x=>Number(x||0).toLocaleString('es-MX'),M=D.metrics;
const stats=[['Tablas',`${M.tables} (${M.operational}+log)`],['Columnas',fmt(M.columns)],['Usuarios',fmt(M.users)],['tb_people',fmt(M.people)],['Productos',fmt(M.products)],['Triggers',`${M.triggers}/${M.trigger_tables} tablas`],['Vistas',`${M.views} (${M.traceviews} trazabilidad)`],['FK',fmt(M.fks)]];$('metrics').innerHTML=stats.map(([a,b])=>`<div class="metric"><strong>${esc(b)}</strong><span>${esc(a)}</span></div>`).join('');
$('source-note').innerHTML=`<b>Cifras verificadas en este respaldo:</b> ${M.tables} tablas físicas (${M.operational} operativas + tb_logs), ${M.columns} columnas; ${fmt(M.users)} filas en tb_users, ${fmt(M.people)} en tb_people y ${fmt(M.products)} productos. ${M.triggers} triggers: ${M.events.INSERT} INSERT, ${M.events.UPDATE} UPDATE y ${M.events.DELETE} DELETE, repartidos en ${M.trigger_tables} tablas. ${M.views} vistas (${M.traceviews} trazabilidad + 1 funcional), ${M.procedures} procedimientos y ${M.functions} funciones.<br><b>Diferencias frente a las cifras del encargo:</b> 061126.sql contiene 75 triggers en 25 tablas operativas, incluida tb_orders, y tb_people tiene 3 filas (tb_users tiene 10,223).`;
for(const d of Object.keys(D.domains)){ $('domain').insertAdjacentHTML('beforeend',`<option>${esc(d)}</option>`);$('dd').insertAdjacentHTML('beforeend',`<option>${esc(d)}</option>`)}
function drawTables(){let q=$('search').value.toLowerCase(),dom=$('domain').value,org=$('origin').value;let ts=D.tables.filter(t=>(!dom||t.domain===dom)&&t.columns.some(c=>(!org||c.origin===org)&&(`${t.name} ${c.name} ${c.sql}`).toLowerCase().includes(q)));$('count').textContent=`${ts.length}/${D.tables.length} tablas`;$('tables').innerHTML=ts.map(t=>{let cs=t.columns.filter(c=>(!org||c.origin===org)&&(`${t.name} ${c.name} ${c.sql}`).toLowerCase().includes(q));return `<details class="entity" ${q?'open':''}><summary><span class="tablename">${esc(t.name)}</span><span class="badge">${esc(t.domain)}</span></summary><div class="ctx"><div><b>Propósito de negocio</b>${esc(t.business)}</div><div><b>Propósito técnico</b>${esc(t.technical)}</div></div><div class="meta">${esc(t.engine)} · ${fmt(t.rows)} filas en INSERT · línea DDL ${t.line} · ${t.columns.length} columnas</div><div class="scroll"><table><thead><tr><th>Columna / clave</th><th>Tipo / dominio / escala</th><th>Cantidad</th><th>Composición</th><th>Naturaleza</th><th>Origen</th><th>Nulabilidad</th><th>Comportamiento INSERT</th></tr></thead><tbody>${cs.map(c=>`<tr><td><span class="col">${esc(c.name)}</span>${c.key?`<div class="keys">${esc(c.key)}</div>`:''}</td><td><span class="sql">${esc(c.domain)}</span></td><td>${esc(c.count)}</td><td>${esc(c.composition)}</td><td>${esc(c.nature)}</td><td><span class="origin ${c.origin.includes('Trigger')?'trigger':c.origin.includes('(SP)')?'sp':c.origin.includes('GENERATED')?'generated':''}" title="${esc(c.detail)}">${esc(c.origin)}</span>${c.detail?`<div class="muted">${esc(c.detail)}</div>`:''}</td><td>${esc(c.null)}</td><td>${esc(c.insert)}</td></tr>`).join('')}</tbody></table></div><details class="fold"><summary>Restricciones, índices, PK/FK y CHECK (${t.constraints.length})</summary><pre>${esc(t.constraints.join('\n')||'Sin restricciones')}</pre></details><details class="fold"><summary>Triggers (${t.triggers.length})</summary><pre>${esc(t.triggers.map(x=>`${x.name} · AFTER ${x.event} · tb_logs(${x.fields.join(', ')})`).join('\n')||'Sin triggers')}</pre></details></details>`}).join('')||'<p>No hay resultados.</p>'}
drawTables();$('search').oninput=drawTables;$('domain').onchange=drawTables;$('origin').onchange=drawTables;
document.querySelectorAll('.tab').forEach(b=>b.onclick=()=>{document.querySelectorAll('.panel,.tab').forEach(x=>x.classList.remove('active'));b.classList.add('active');$(b.dataset.panel).classList.add('active');if(b.dataset.panel==='eer')setTimeout(drawEER,30)});
function drawTriggers(){let q=$('ts').value.toLowerCase(),ev=$('te').value,rows=D.triggers.filter(t=>(!ev||t.event===ev)&&(`${t.name} ${t.table}`).toLowerCase().includes(q));$('tc').textContent=`${rows.length}/${D.triggers.length}`;$('trigger-list').innerHTML=rows.map(t=>`<article class="box"><code>${esc(t.name)}</code><p>${esc(t.table)} · AFTER ${esc(t.event)}</p><p>tb_logs(${esc(t.fields.join(', '))})</p></article>`).join('')}
drawTriggers();$('ts').oninput=drawTriggers;$('te').onchange=drawTriggers;
$('audit-note').innerHTML=`Columnas de tb_logs: ${esc(D.logcols.join(', '))}. ID se asigna por AUTO_INCREMENT y operation_date tiene DEFAULT CURRENT_TIMESTAMP. ${D.invalid.length?`Algunos triggers intentan columnas que no existen en tb_logs: <b>${esc(D.invalid.join(', '))}</b>; sus INSERT no coinciden con el DDL.`:'Los campos escritos por triggers coinciden con el DDL.'} Cobertura real ${M.triggers}/${M.operational*3} triggers.`;
function drawViews(){let q=$('vs').value.toLowerCase(),kind=$('vk').value;let vs=D.views.filter(v=>(!kind||v.kind===kind)&&(`${v.name} ${v.tables.join(' ')}`).toLowerCase().includes(q));$('views').innerHTML=vs.map(v=>`<article class="box"><code>${esc(v.name)}</code><span class="badge" style="float:right">${esc(v.kind)}</span><p>Fuentes: ${esc(v.tables.join(', ')||'No reconocidas automáticamente')}</p><details><summary class="fold">Definición SQL</summary><pre>${esc(v.sql)}</pre></details></article>`).join('')}
drawViews();$('vs').oninput=drawViews;$('vk').onchange=drawViews;
const pnotes={sp_attend_order:'Valida el estado, descuenta stock y actualiza pedido/subórdenes.',sp_authorize_payment:'Inserta transacción y actualiza pago y pedido.',sp_deliver_order:'Genera envíos y actualiza estados de entrega.',sp_generate_users_batch:'Generación por lotes; referencia tb_cancellations, ausente del DDL.',sp_insert_single_user:'Inserción unitaria; usa nickname/country/birthdate que no existen en tb_users.',sp_register_new_user:'Alta transaccional de cuenta/persona; aplica MD5 a contraseña.',sp_restore_product:'Reactiva un producto.',sp_soft_delete_product:'Baja lógica de producto.',sp_soft_delete_user:'Baja lógica con revisión de privilegios.'};
$('routines').innerHTML=D.procedures.map(n=>`<article class="box"><code>${esc(n)}</code><p class="sql">${esc(D.procsigs[n])}</p><p>${esc(pnotes[n]||'Rutina almacenada.')}</p></article>`).join('')+D.functions.map(n=>`<article class="box"><code>${esc(n)}</code><p class="sql">${esc(D.funcsigs[n])}</p></article>`).join('');
let positions={},zoom=1;const W=246,H=120,GX=300,GY=158,OX=18,OY=24;
function drawEER(){const c=$('canvas');c.querySelectorAll('.node').forEach(n=>n.remove());positions={};const dom=$('dd').value,q=$('ds').value.toLowerCase();let max=0;D.tables.forEach(t=>{let col=Object.keys(D.domains).indexOf(t.domain),row=D.domains[t.domain].indexOf(t.name);positions[t.name]={x:OX+col*GX,y:OY+row*GY,col,row};max=Math.max(max,row)});c.style.width=(OX*2+3*GX+W)+'px';c.style.height=(OY*2+max*GY+H+38)+'px';for(const t of D.tables){let p=positions[t.name],hide=(dom&&dom!==t.domain)||(q&&!(`${t.name} ${t.columns.map(x=>x.name).join(' ')}`).toLowerCase().includes(q));let pks=t.columns.filter(x=>x.key.includes('PK')),fks=t.columns.filter(x=>x.key.includes('FK')),n=document.createElement('article');n.className=`node ${t.weak?'weak':''} ${hide?'hide':''}`;n.dataset.table=t.name;n.style.left=p.x+'px';n.style.top=p.y+'px';n.innerHTML=`<div class="node-head"><span>${esc(t.name)}</span><span>${esc(t.domain)}</span></div><div class="node-body">${pks.map(x=>`<div class="pkline">PK ${esc(x.name)} · ${esc(x.type)}</div>`).join('')||'<div>PK no declarada</div>'}${fks.map(x=>`<div class="fkline">FK ${esc(x.name)} → ${esc((x.key.split('→')[1]||'').trim())}</div>`).join('')||'<div>Sin FK declaradas</div>'}</div><div class="node-foot">${t.weak?'Entidad dependiente · ':''}${t.columns.length} atributos · clic para ficha</div>`;n.onclick=()=>openTable(t.name);n.onmouseenter=()=>focus(t.name,true);n.onmouseleave=()=>focus(t.name,false);c.appendChild(n)}drawEdges()}
function drawEdges(){const svg=$('edges'),c=$('canvas'),ns='http://www.w3.org/2000/svg';svg.setAttribute('width',c.style.width);svg.setAttribute('height',c.style.height);svg.setAttribute('viewBox',`0 0 ${parseInt(c.style.width)} ${parseInt(c.style.height)}`);svg.innerHTML='';for(const r of D.rels){let a=positions[r.parent],b=positions[r.child],na=c.querySelector(`.node[data-table="${CSS.escape(r.parent)}"]`),nb=c.querySelector(`.node[data-table="${CSS.escape(r.child)}"]`);if(!na||!nb||na.classList.contains('hide')||nb.classList.contains('hide'))continue;let x1,y1,x2,y2,path;if(r.parent===r.child){x1=a.x+W;y1=a.y+16;x2=a.x+W;y2=a.y+45;path=`M${x1},${y1} C${x1+84},${y1-35} ${x2+84},${y2+34} ${x2},${y2}`}else if(a.col===b.col){x1=a.x+W/2;y1=a.y+H;x2=b.x+W/2;y2=b.y;let m=(y1+y2)/2;path=`M${x1},${y1} C${x1+25},${m} ${x2+25},${m} ${x2},${y2}`}else{let right=b.x>a.x;x1=right?a.x+W:a.x;y1=a.y+30;x2=right?b.x:b.x+W;y2=b.y+30;let m=(x1+x2)/2;path=`M${x1},${y1} C${m},${y1} ${m},${y2} ${x2},${y2}`}let edge=document.createElementNS(ns,'path');edge.setAttribute('d',path);edge.setAttribute('class',`edge ${r.identifying?'ident':''}`);edge.dataset.a=r.parent;edge.dataset.b=r.child;let title=document.createElementNS(ns,'title');title.textContent=`${r.name} · ${r.parent} 1:${r.one?'1':'N'} ${r.child} · ${r.cc.join(',')} → ${r.parent}.${r.pp.join(',')} · ON DELETE ${r.delete} · ON UPDATE ${r.update} · participación padre parcial, hija ${r.optional?'parcial':'total'}`;edge.appendChild(title);svg.appendChild(edge);let label=document.createElementNS(ns,'text');label.setAttribute('x',(x1+x2)/2);label.setAttribute('y',(y1+y2)/2-3);label.setAttribute('text-anchor','middle');label.setAttribute('class','edge-label');label.textContent=`1:${r.one?'1':'N'}`;svg.appendChild(label)}$('rc').textContent=`${D.rels.length} relaciones FK · 1:N / 1:1`}
function focus(n,on){document.querySelectorAll('.node').forEach(e=>e.classList.toggle('focus',on&&(e.dataset.table===n||D.rels.some(r=>(r.parent===n&&r.child===e.dataset.table)||(r.child===n&&r.parent===e.dataset.table)))));document.querySelectorAll('.edge').forEach(e=>e.classList.toggle('focus',on&&(e.dataset.a===n||e.dataset.b===n)))}
function openTable(n){document.querySelector('[data-panel="dict"]').click();$('search').value=n;drawTables();setTimeout(()=>{let a=[...document.querySelectorAll('.entity')].find(x=>x.querySelector('.tablename')?.textContent===n);if(a){a.open=true;a.scrollIntoView({behavior:'smooth',block:'start')}}},100)}
$('ds').oninput=drawEER;$('dd').onchange=drawEER;$('zp').onclick=()=>{zoom=Math.min(1.5,zoom+.1);$('canvas').style.zoom=zoom};$('zm').onclick=()=>{zoom=Math.max(.55,zoom-.1);$('canvas').style.zoom=zoom};$('zr').onclick=()=>{zoom=1;$('canvas').style.zoom=1;$('diagram-scroll').scrollTo(0,0)};
</script></body></html>'''.replace('__JSON__',jsondata)
pathlib.Path('index.html').write_text(page,encoding='utf-8')
print(json.dumps({'index':'index.html','size':pathlib.Path('index.html').stat().st_size,'metrics':metrics,'fks':len(rels),'invalid_logs':invalid},ensure_ascii=False))

