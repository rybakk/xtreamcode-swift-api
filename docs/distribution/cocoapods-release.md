# CocoaPods Release Guide

Ce guide explique comment publier une nouvelle version de Xtreamcode Swift API sur CocoaPods.

## Prérequis

1. Compte CocoaPods Trunk enregistré
2. Tag Git créé (ex: `v1.0.0`)
3. `xtreamcode-swift-api.podspec` à jour

## Étape 1 : S'inscrire sur CocoaPods Trunk (première fois uniquement)

```bash
pod trunk register your-email@example.com 'Your Name' --description='Xtreamcode Swift API'
```

Vérifiez votre email et cliquez sur le lien de confirmation.

## Étape 2 : Vérifier le podspec

```bash
# Lint local (rapide)
pod lib lint xtreamcode-swift-api.podspec --allow-warnings

# Lint complet avec validation réseau
pod spec lint xtreamcode-swift-api.podspec --allow-warnings
```

## Étape 3 : Publier sur CocoaPods

```bash
pod trunk push xtreamcode-swift-api.podspec --allow-warnings
```

## Étape 4 : Vérifier la publication

```bash
# Rechercher le pod
pod search XtreamcodeSwiftAPI

# Voir les infos
pod trunk info XtreamcodeSwiftAPI
```

## Troubleshooting

### Erreur : "Unable to find a pod with name"
Attendez quelques minutes, la propagation peut prendre du temps.

### Erreur : "You are not the owner"
Vérifiez que vous êtes bien enregistré :
```bash
pod trunk me
```

### Erreur de validation
Corrigez les erreurs dans le podspec et réessayez.

## Notes

- CocoaPods utilise le tag Git spécifié dans `s.source`
- Assurez-vous que le tag est poussé sur GitHub avant de publier
- Les `--allow-warnings` sont parfois nécessaires pour les warnings de dépendances

## Voir aussi

- [CocoaPods Trunk Guide](https://guides.cocoapods.org/making/getting-setup-with-trunk.html)
- [Podspec Syntax Reference](https://guides.cocoapods.org/syntax/podspec.html)
