# Carthage Integration Guide

Ce guide explique comment intégrer Xtreamcode Swift API dans votre projet via Carthage.

## Installation

### Étape 1 : Créer un Cartfile

Créez un fichier `Cartfile` à la racine de votre projet :

```ruby
github "your-org/xtreamcode-swift-api" ~> 1.0
```

### Étape 2 : Installer les dépendances

```bash
carthage update --use-xcframeworks --platform iOS
# ou pour toutes les plateformes :
carthage update --use-xcframeworks
```

### Étape 3 : Intégrer dans Xcode

1. Dans Xcode, sélectionnez votre projet
2. Allez dans l'onglet "General" de votre target
3. Faites glisser `Carthage/Build/XtreamcodeSwiftAPI.xcframework` dans "Frameworks, Libraries, and Embedded Content"
4. Assurez-vous que "Embed & Sign" est sélectionné

### Étape 4 : Importer dans votre code

```swift
import XtreamcodeSwiftAPI

let api = XtreamcodeSwiftAPI(
    baseURL: URL(string: "https://portal.example.com")!,
    credentials: XtreamCredentials(username: "demo", password: "secret")
)
```

## Build depuis les sources

Si vous souhaitez construire le XCFramework vous-même :

```bash
# Cloner le dépôt
git clone https://github.com/your-org/xtreamcode-swift-api.git
cd xtreamcode-swift-api

# Construire le XCFramework
./scripts/build-xcframework.sh

# Le résultat sera dans Artifacts/XtreamcodeSwiftAPI.xcframework
```

## Plateformes supportées

- iOS 14.0+
- macOS 12.0+
- tvOS 15.0+

## Troubleshooting

### Erreur : "Building universal frameworks with common architectures"
Utilisez `--use-xcframeworks` pour les builds modernes :
```bash
carthage update --use-xcframeworks
```

### Erreur : "Command PhaseScriptExecution failed"
Ajoutez un run script phase dans Xcode :
```bash
/usr/local/bin/carthage copy-frameworks
```

Avec les Input Files :
```
$(SRCROOT)/Carthage/Build/iOS/XtreamcodeSwiftAPI.framework
```

### XCFramework not found
Assurez-vous que Carthage a bien construit pour votre plateforme :
```bash
carthage update --use-xcframeworks --platform iOS
```

## Notes

- Carthage ne gère pas les dépendances transitives
- Alamofire doit être ajouté séparément dans votre Cartfile :
  ```ruby
  github "Alamofire/Alamofire" ~> 5.10
  ```

## Voir aussi

- [Carthage Documentation](https://github.com/Carthage/Carthage)
- [XCFrameworks Guide](https://help.apple.com/xcode/mac/11.4/#/dev544efab96)
