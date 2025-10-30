# Guide tvOS – Intégration Xtreamcode Swift API

Ce guide décrit la mise en place d’une application tvOS s’appuyant sur `XtreamcodeSwiftAPI` pour la lecture Live/EPG.

## Pré-requis
- tvOS 15 minimum, Xcode 16.
- `XtreamcodeSwiftAPI` intégré via SwiftPM (recommandé) ou XCFramework.
- Player basé sur `AVPlayerViewController`.

## Architecture recommandée
1. **ViewModel Combine**  
   - Injection d’un `XtreamcodeSwiftAPI` configuré (cache mémoire + TTL adapté tvOS).  
   - Exposition de Publishers (`liveCategoriesPublisher`, `liveStreamsPublisher`) pour alimenter les vues.
2. **Coordinator**  
   - Navigation catégories → chaînes → details/EPG.
3. **Player module**  
   - `LivePlayerController` encapsulant `AVPlayerViewController`, gérant les erreurs via `XtreamError`.

## Remote Siri & focus
- Utiliser `UIFocusGuide` pour naviguer entre catégories/chaînes.
- Mapping Siri Remote :
  - `play/pause` → `AVPlayer` `play()` / `pause()`.
  - `Menu` → sortie du player (coordonner via delegate).
- Prévoir un `UIPress` handler pour `UIRemoteNotificationCenter`.

## Background audio
- Activer `Audio, AirPlay, Picture in Picture` dans les capabilities.
- Configurer `AVAudioSession` (`category: .playback`) au lancement.
- Gérer la reprise en avant-plan en réévaluant la connexion (`liveStreamURL(forceRefresh: true)` si besoin).

## DRM & restrictions
- Si le flux impose un token éphémère, appeler `liveStreamURL(forceRefresh: true)` juste avant lecture.
- Supportez les erreurs `XtreamError.liveUnavailable` / `catchupDisabled` en affichant des alertes dédiées.

## Workflow type
```swift
let api = XtreamcodeSwiftAPI(configuration: configuration)

api.liveCategoriesPublisher()
    .receive(on: DispatchQueue.main)
    .sink(receiveCompletion: { completion in
        if case let .failure(error) = completion {
            // Presenter affiche l’erreur
        }
    }, receiveValue: { categories in
        self.categories = categories
    })
    .store(in: &cancellables)
```

Pour la lecture :
```swift
Task {
    do {
        if let url = try await api.liveStreamURL(for: stream.id, forceRefresh: true) {
            player.replaceCurrentItem(with: AVPlayerItem(url: url))
            player.play()
        }
    } catch {
        // Logger + UI erreur
    }
}
```

## Tests & QA
- UI Tests : focus navigation, Siri Remote interactions, lecture continue.
- Couverture : `swift test --filter XtreamAPIIntegrationTests`.
- Checklist manuelle : voir `docs/qa/live_epg_checklist.md` (à compléter).

