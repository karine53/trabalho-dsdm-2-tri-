# NutriBem

## Descrição

O NutriBem é um aplicativo desenvolvido em Flutter com o objetivo de auxiliar os usuários no acompanhamento de seus hábitos alimentares. O sistema permite o cadastro de refeições, consulta ao histórico, visualização de estatísticas e envio de notificações para lembrar os horários das refeições.

Este projeto foi desenvolvido para a disciplina de Desenvolvimento de Sistemas para Dispositivos Móveis (DSDM).

## Objetivo

Desenvolver um aplicativo móvel que incentive hábitos alimentares saudáveis por meio do registro de refeições, acompanhamento do consumo alimentar e envio de lembretes.

## Problema

Muitas pessoas possuem dificuldade em manter uma rotina alimentar organizada, esquecendo refeições ou não acompanhando seu consumo diário.

## Solução

O NutriBem oferece uma plataforma simples para registrar refeições, consultar o histórico, visualizar estatísticas e receber notificações, contribuindo para uma alimentação mais equilibrada.

## Funcionalidades

* Cadastro de refeições;
* Edição de refeições;
* Exclusão de refeições;
* Consulta ao histórico de refeições;
* Estatísticas semanais;
* Cálculo do consumo médio de calorias;
* Sistema de pontuação semanal;
* Notificações locais para lembretes de refeições.

## Tecnologias utilizadas

* Flutter
* Dart
* SQLite
* sqflite
* flutter_local_notifications
* permission_handler
* shared_preferences
* intl
* timezone

## Estrutura do projeto

```text
lib/
├── database/
├── models/
├── pages/
├── services/
├── widgets/
└── main.dart
```

## Banco de dados

O aplicativo utiliza SQLite para armazenar localmente as informações das refeições cadastradas pelo usuário.

Os dados armazenados incluem:

* nome da refeição;
* descrição;
* categoria;
* quantidade de calorias;
* data da refeição.

## Notificações

O sistema utiliza o pacote `flutter_local_notifications` para o envio de notificações locais. A solicitação de permissão para notificações é realizada por meio do pacote `permission_handler`.

## Como executar o projeto

1. Clone o repositório:

```bash
git clone https://github.com/karine53/trabalho-dsdm-2-tri-.git
```

2. Entre na pasta do projeto:

```bash
cd trabalho-dsdm-2-tri-
```

3. Instale as dependências:

```bash
flutter pub get
```

4. Execute o aplicativo:

```bash
flutter run
```

## Desenvolvedoras

* Karine Johann
* Sophia

## Licença

Projeto desenvolvido para fins acadêmicos.
