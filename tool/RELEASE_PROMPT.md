# RELEASE PROMPT — Japanese Study (dipakai setiap update versi)

> Jalankan alur ini setiap kali ada update aplikasi yang layak rilis
> (fitur baru, perbaikan penting, perubahan kurikulum). Update kecil
> tanpa versi (typo komentar, docs) cukup commit + push biasa.

## 0. Prasyarat (jangan rilis kalau gagal)

```powershell
flutter analyze        # harus: No issues found
flutter test           # harus: All tests passed
```

## 1. Naikkan versi (semver)

- Fitur baru / bab baru → **minor**: `1.2.0+3` → `1.3.0+4`
- Perbaikan bug saja → **patch**: `1.2.0+3` → `1.2.1+4`
- Edit `pubspec.yaml` (`version: X.Y.Z+N`, N = build number naik 1 tiap rilis)
- Tambah entri `CHANGELOG.md` (Indonesia, poin perubahan user-facing)

## 2. Commit + push (jangan pernah commit secret/build)

```powershell
git status --short          # pastikan tidak ada file sensitif:
                            # android/key.properties, google-services.json,
                            # backend/.env, *.jks, build/
git add lib test backend docs pubspec.yaml CHANGELOG.md tool
git commit -m "<tipe>: <ringkasan singkat Indonesia>"
# tipe: feat | fix | security | chore | docs | curriculum
git push origin main
git log --oneline -1        # catat hash commit untuk catatan rilis
```

## 3. Build rilis signed (di mesin lokal, keystore tidak di-commit)

```powershell
flutter build apk --release
flutter build appbundle --release
# hasil:
#   build/app/outputs/flutter-apk/app-release.apk
#   build/app/outputs/bundle/release/app-release.aab
```

## 4. Buat GitHub Release via `gh`

```powershell
gh release create vX.Y.Z `
  --title "vX.Y.Z" `
  --notes "Ringkasan (salin dari CHANGELOG) + hash commit" `
  build/app/outputs/flutter-apk/app-release.apk `
  build/app/outputs/bundle/release/app-release.aab
gh release view vX.Y.Z --json tagName,assets --jq "{tag, assets: [.assets[] | .name]}"
```

## 5. Deploy backend ke server (MANUAL, butuh kredensial runtime)

Kredensial SSH (`root@192.168.100.10`) **tidak disimpan di repo/chat** —
minta ke owner setiap sesi. Jangan pernah `echo` password ke log.

```bash
ssh root@192.168.100.10
cd /opt/japanese-study-v2
git pull
docker compose up -d --build   # migrasi jalan otomatis via entrypoint
docker compose ps
curl -k https://192.168.100.230/api/health
```

## 6. Verifikasi pasca-rilis

- [ ] `gh release view` menampilkan 2 asset (APK + AAB)
- [ ] `/api/health` → `{"ok": true}`
- [ ] Smoke test aplikasi: Home → Continue → 1 lesson → review
- [ ] Rotasi kredensial yang sempat dibagikan di chat (wajib)
