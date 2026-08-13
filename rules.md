# Diretrizes de Desenvolvimento: Projeto Mobile (Flutter)

## 📱 Visão Geral
Este é um novo projeto de aplicativo mobile multiplataforma (Android e iOS). O objetivo primário é desenvolver uma aplicação robusta, escalável e de fácil manutenção, focando na performance e na confiabilidade da sincronização de dados.

## 🛠️ Stack Tecnológico Base
*   **Framework:** Flutter (Dart)
*   **Banco de Dados Local:** SQLite (recomendado uso de pacotes como `sqflite` ou `drift`)
*   **Conexão em Nuvem:** Consumo de API RESTful / Integração com backend remoto

## 🏗️ Arquitetura e Estrutura de Software
O código deve ser projetado com foco em escalabilidade e separação clara de responsabilidades.
*   **Padrão Arquitetural:** Utilize Clean Architecture em conjunto com um padrão de gerência de estado consolidado (como BLoC, Riverpod ou Provider).
*   **Desacoplamento:** A interface de usuário (UI), a lógica de negócios (Domain) e a camada de dados (Data) devem ser independentes. A UI não deve fazer chamadas diretas ao banco de dados ou à API.
*   **Padrão Repository:** Implemente o padrão *Repository* para mediar a comunicação de dados. A lógica de negócio não precisa saber se o dado vem do SQLite ou da Nuvem.

## 💾 Estratégia de Dados e Sincronização
*   **Abordagem Offline-First:** O aplicativo deve ser funcional sem conexão com a internet. O banco de dados local (SQLite) deve atuar como a "fonte única da verdade" (Single Source of Truth) para a interface.
*   **Sincronização:** As requisições à nuvem devem atualizar o banco de dados local, e a UI deve reagir apenas às mudanças no banco local. Operações de escrita devem ser salvas localmente e sincronizadas com a nuvem em background.

## 💻 Qualidade de Código e Legibilidade
O código será mantido por humanos, portanto, a legibilidade é tão importante quanto a eficiência.
*   **Clareza e Nomenclatura:** Escolha nomes descritivos e explícitos para variáveis, funções e classes. Evite abreviações obscuras ou acrônimos não padronizados. O código deve ser autoexplicativo na maior parte do tempo.
*   **Princípios SOLID e DRY:** Aplique fortemente os princípios SOLID. Evite duplicação de código (DRY - Don't Repeat Yourself) extraindo lógicas comuns para *helpers*, *services* ou *widgets* reutilizáveis.
*   **Comentários Estratégicos:** Documente o "porquê" de uma decisão técnica, regra de negócio complexa ou *workaround*. Não comente o óbvio (o "o quê" o código faz).
*   **Tratamento de Erros (Error Handling):** Implemente tratamento de exceções robusto em todas as chamadas de rede e operações de banco de dados. Falhas na nuvem não devem quebrar o aplicativo; devem ser tratadas de forma silenciosa ou comunicadas de forma amigável ao usuário, mantendo o estado local preservado.
*   **Linting e Formatação:** Respeite rigorosamente as regras do `flutter_lints` e mantenha a formatação padrão do Dart (`dart format`). Nenhuma PR (Pull Request) imaginária passaria com warnings de linter.