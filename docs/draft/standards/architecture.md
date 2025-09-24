現状残ってるのは、CLAUDE.mdの中にある以下の記述のみ。

```
#### 概要

このプロジェクトは、一言で表すなら、「**フィーチャーベースの『サービスレイヤー・アーキテクチャ』(Feature-based Service Layer Architecture)**」を採用しています。ただし、このアーキテクチャと類似しているClean Architectureとの明確な違いは、「依存性の逆転は使わず、UI→Service→Repositoryという直線的な依存関係にしている」点です。

このアーキテクチャについては、以下のような言い換えも可能です：

- フィーチャーベース・レイヤードアーキテクチャ (Feature-based Layered Architecture)
- サービスレイヤー・アーキテクチャ (Service Layer Architecture)
- 直線的レイヤードアーキテクチャ (Linear Layered Architecture)
```

ある程度これでもまとまっているけど、細かな思想が含まれていない気がするので、後付でもいいから文書として詰めていきたい。

まず、
- feature-basedである
- presentation->service->repositoryという直線的な依存関係を持つ(modelは全てのやりとりの基準として)

みたいな所は結構固い。優先順位としてもfeature-based->layeredは決定。