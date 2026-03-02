# Rádio FEM App (Android)

Aplicativo Android inicial para a web rádio **radio.forroemmilao.com** usando AzuraCast.

## O que já está implementado

- Streaming ao vivo da rádio (`android.mp3`) com Play/Pause
- Player com `MediaSession` (foreground service) para controle por fones, bluetooth, lockscreen e notificação de mídia
- Leitura do endpoint AzuraCast `api/nowplaying/radiofem`
- Atualização automática do "tocando agora" a cada 15 segundos
- Exibição de ouvintes atuais
- Visual do app alinhado com a identidade da rádio (paleta/fundo em estilo forró)
- Aba de programação semanal dinâmica via `api/station/radiofem/schedule` com filtro para títulos iniciados em `PROG`
- Aba de podcasts com lista e episódios via endpoints públicos do AzuraCast
- Reprodução de episódios de podcast dentro do próprio app (sem abrir navegador)
- Botão para voltar do modo Podcast para o Ao Vivo no player principal

## Stack

- Kotlin
- Jetpack Compose (Material 3)
- Media3 ExoPlayer
- Retrofit + Gson

## Como executar

1. Instale Android Studio (versão recente) com JDK 17.
2. Abra a pasta deste projeto no Android Studio.
3. Aguarde o Gradle Sync.
4. Rode no emulador ou celular Android.

## Publicação automática na Play Store (API)

Este projeto está configurado com **Gradle Play Publisher** para subir versões direto do terminal.

### 1) Preparar credenciais

1. No Google Cloud, crie uma **Service Account**.
2. No Play Console, em **Setup > API access**, vincule o projeto Google Cloud.
3. Conceda permissões da Service Account para o app `com.forroemmilao.radiofem` (release manager/admin conforme sua política).
4. Baixe o JSON da chave e salve na raiz do projeto como:
   - `play-account.json`

Referência de formato:
- `play-account.json.example`

### 2) Gerar e publicar via terminal

Publicar para teste interno (somente App Bundle, track padrão):

```bash
./gradlew :app:publishReleaseBundle
```

Publicar App Bundle + metadata da Play Store (descrições, release notes e screenshots):

```bash
./gradlew :app:publishReleaseApps
```

Publicar para outro track explicitamente:

```bash
./gradlew :app:publishReleaseBundle --track closed
./gradlew :app:publishReleaseBundle --track production
```

### 3) Comportamento atual da configuração

- Upload em formato **AAB** (App Bundle).
- Track padrão: `internal`.
- Credenciais lidas de `play-account.json` na raiz.
- Metadata automática em `app/src/main/play`.

## Configurações da rádio

As variáveis principais ficam em `app/build.gradle.kts`:

- `BASE_URL`
- `STATION_SHORTCODE`
- `STREAM_URL`

## Próximas evoluções sugeridas

- Integrar eventos especiais da aba Programação com Google Calendar API
- Notificação persistente com controles de mídia
- Integração Android Auto
- Player interno para reproduzir episódios de podcast sem sair do app
- Push notification para início de programas ao vivo
