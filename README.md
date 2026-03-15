# Radio FEM App

Migracao do app original Android nativo para uma base Flutter com suporte a Android e iPhone, usando os mesmos endpoints AzuraCast da radio `radio.forroemmilao.com`.

## Backup do Android original

O projeto Android puro foi salvo separadamente em:

`/mnt/d/Radio_FEM_App_android_backup_2026-03-07`

## O que foi migrado para Flutter

- Streaming ao vivo da radio com play/pause
- Leitura do endpoint `api/nowplaying/radiofem`
- Atualizacao automatica do "now playing" a cada 15 segundos
- Exibicao de ouvintes atuais
- Programacao semanal e mensal via `api/station/radiofem/schedule`
- Lista de podcasts e episodios via endpoints publicos do AzuraCast
- Reproducao de episodios de podcast dentro do app
- Retorno do modo podcast para o ao vivo
- Deep links internos para comandos remotos (`play-live`, `pause`, `resume`)
- Bridge HTTP local em `127.0.0.1` para integracao com o app do relogio no Android
- Estrutura nativa gerada para `android/` e `ios/`
- Launcher icon gerado para Android e iOS a partir de `icon.png`
- Splash nativo gerado para Android e iOS a partir de `icon_low.png`

## Stack atual

- Flutter
- Dart
- `audio_service`
- `just_audio`
- `http`
- `provider`

## Como executar

1. Instale o Flutter SDK e confirme com `flutter doctor`.
2. Abra este diretorio no VS Code ou Android Studio.
3. Rode `flutter pub get`.
4. Para Android, use `flutter run`.
5. Para iPhone, abra `ios/Runner.xcworkspace` no Xcode ou rode `flutter run` em um Mac com Xcode configurado.

## Build

Android debug:

```bash
flutter build apk --debug
```

iPhone:

```bash
flutter build ios
```

Observacao: o build iOS nao foi validado neste ambiente porque esta maquina nao tem Xcode.

## Store metadata

- App Store Connect: [APPSTORE_MATERIALS_ios_v1.0.4.md](/mnt/d/Radio_FEM_App/APPSTORE_MATERIALS_ios_v1.0.4.md)
- Play Console: [PLAYSTORE_MATERIALS_radio_fem_v1.0.6.md](/mnt/d/Radio_FEM_App/PLAYSTORE_MATERIALS_radio_fem_v1.0.6.md)
- Export options for archive/export: [ExportOptions-AppStore.plist](/mnt/d/Radio_FEM_App/ios/ExportOptions-AppStore.plist)

## Watch bridge

- O Android app expoe um bridge HTTP local em `http://127.0.0.1:43871`.
- O app do relogio envia os comandos `play-live` e `pause` para esse bridge via `Zepp side service`.
- Este fluxo e um prototipo Android-first. Para funcionar, o app Radio FEM precisa ter sido aberto no celular e o processo precisa continuar ativo.

## Configuracoes da radio

As constantes principais estao em [app_config.dart](/mnt/d/Radio_FEM_App/lib/src/config/app_config.dart).

- `baseUrl`
- `stationShortcode`
- `streamUrl`
- `contactEmail`
- `localBridgePort`
- `localBridgeKey`

## Audience analytics API

O app agora suporta os relatórios privados de audiencia de 30 dias do AzuraCast para mostrar:

- total de ouvintes nos ultimos 30 dias
- top 5 paises por audiencia

Para ativar isso, a build precisa receber uma API key da estacao com permissao de leitura de relatórios (`view station reports`).

Voce pode fornecer a chave de 2 formas:

1. Em [key.properties](/mnt/d/Radio_FEM_App/key.properties) ou [android/local.properties](/mnt/d/Radio_FEM_App/android/local.properties):

```properties
radiofem.analyticsApiKey=YOUR_STATION_API_KEY
```

2. Ou por variavel de ambiente:

```bash
export RADIO_FEM_ANALYTICS_API_KEY=YOUR_STATION_API_KEY
```

Depois disso, os builds Android e o publish via Gradle/Play Console passam a embutir automaticamente a chave no `dart-define` usado pelo app.
