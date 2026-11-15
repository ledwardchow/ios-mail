# SPDX-License-Identifier: GPL-3.0-or-later
import pathlib,tomllib,sys,json
base=pathlib.Path(__file__).parent
sys.path.insert(0,str(base/'build-tools'))
import tomli_w
root=base/'clients'
read=lambda p:tomllib.loads(p.read_text())
manifest=root/'Cargo.toml'; d=read(manifest); wd=d['workspace']['dependencies']
# Cargo resolves optional dependencies even when disabled. This build retains only
# the default, non-foundation-search product used by upstream iOS build script.
removed={'mail-search','mail-search-perf','mail-historic-search-load'}
seen=set(); changed=[]; todo=['project/mail/rust/mail/mail-uniffi','project/mail/rust/uniffi/uniffi-bindgen']
while todo:
 rel=todo.pop()
 if rel in seen:continue
 seen.add(rel); p=root/rel/'Cargo.toml'; c=read(p)
 groups=[c]+list(c.get('target',{}).values())
 for group in groups:
  for section in ('dependencies','build-dependencies','dev-dependencies'):
   deps=group.get(section,{})
   for name,v in list(deps.items()):
    if name in removed:
     del deps[name];changed.append(str(p.relative_to(base))+': remove '+name);continue
    if not isinstance(v,dict):continue
    spec=wd.get(name,{}) if v.get('workspace') else v
    if isinstance(spec,dict) and 'path' in spec:
     path=(root/spec['path']) if v.get('workspace') else (p.parent/spec['path']).resolve()
     if path.is_relative_to(root) and path.name!='muon':todo.append(str(path.relative_to(root)))
 for name in list(c.get('features',{})):
  if name.startswith('foundation_search'):del c['features'][name]
 for name,vals in c.get('features',{}).items():
  c['features'][name]=[v for v in vals if not any(x in v for x in removed) and not v.startswith('foundation_search')]
 if c!=read(p):p.write_text(tomli_w.dumps(c))
d['workspace']['members']=sorted(seen)
for name in removed:wd.pop(name,None)
patch=d.setdefault('patch',{}).setdefault('proton',{})
for name in ['gopenpgp-sys','proton-crypto','proton-crypto-account','proton-crypto-subtle','proton-srp','proton-rpgp']:
 patch[name]={'path':str(base/'crypto'/name)}
patch['muon-proc']={'path':str(base/'rust-mail-vendor/muon-proc-0.5.0')}
manifest.write_text(tomli_w.dumps(d))
empty=base/'empty-proton-registry';empty.mkdir(exist_ok=True)
config={'net':{'git-fetch-with-cli':True},'registries':{'proton':{'index':'sparse+https://rust-registry.proton.me/index/'}},'source':{'proton':{'registry':'sparse+https://rust-registry.proton.me/index/','replace-with':'empty-proton'},'empty-proton':{'directory':str(empty)}}}
(root/'.cargo/config.toml').write_text(tomli_w.dumps(config))
# Avoid nested directory config overriding build isolation and retain only iOS targets.
(root/'project/mail/rust/.cargo/config.toml').write_text('')
(root/'project/mail/rust/rust-toolchain.toml').write_text('[toolchain]\nchannel="1.93.0"\nprofile="minimal"\ntargets=["aarch64-apple-ios", "aarch64-apple-ios-sim"]\n')
(base/'reconstruction-report.json').write_text(json.dumps({'members':sorted(seen),'removed_default_disabled_optional_dependencies':changed,'patches':patch},indent=2))
print('Prepared',len(seen),'workspace members; all Proton registry reads redirected to empty local directory')
# Reuse the validated public-resolution lockfile when distributed with this recipe.
lock=base/'Cargo.lock.public'
if lock.exists():
 import shutil
 shutil.copyfile(lock,root/'Cargo.lock')
build_script=root/'project/mail/rust/rust-build/build_ios_framework_uniffi.sh'
s=build_script.read_text().replace('cargo build --profile','cargo build --locked --profile').replace('cargo run --release','cargo run --locked --release').replace('cargo metadata --format-version','cargo metadata --locked --format-version')
build_script.write_text(s)
