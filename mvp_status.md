# Status do MVP - EntreNós

**Data:** 12/02/2026
**Status:** ✅ Implementado

## 🚀 Funcionalidades Entregues

### 1. Autenticação e Conexão (P0)
-   ✅ **Tela de Login:** Implementada. O usuário agora insere seu nome antes de continuar.
-   ✅ **Fluxo de Conexão:**
    -   **Gerar Código:** Gera um código aleatório (ex: `XJ92KA`) para compartilhar.
    -   **Inserir Código:** Valida o código e simula conexão com feedback visual.
    -   **Persistência:** O app lembra se você está conectado e quem você é.

### 2. Navegação e Menu (P0)
-   ✅ **Botão de Configurações:** Adicionado ao cabeçalho da Home.
-   ✅ **Tela de Menu:**
    -   Exibe Foto e Nome do Usuário.
    -   Opção de **Desconectar** (Resetar app).
    -   Acesso a **Termos** e **Ajuda**.
-   ✅ **Tutorial:** Tela explicativa de como adicionar o Widget no iOS.

### 3. Core Experience (P1)
-   ✅ **Pincel Neon:** O traço do desenho agora possui um brilho real (Glow Effect) em camadas, destacando-se no fundo escuro.
-   ✅ **Histórico Funcional:**
    -   Ao enviar um desenho, ele é salvo localmente no dispositivo.
    -   A tela de Histórico carrega e exibe esses desenhos reais.
    -   **Empty State:** Tela amigável quando não há desenhos.

---

## 📸 Como Testar
1.  **Login:** Insira seu nome.
2.  **Conexão:** Gere um código ou digite um (ex: `TESTE`).
3.  **Desenhar:** Use o pincel e veja o efeito Neon.
4.  **Enviar:** Toque em Enviar. O desenho vai para o Histórico.
5.  **Menu:** Acesse o menu (ícone de engrenagem) para ver o Tutorial ou Sair.

---

## 📝 Próximos Passos (Pós-MVP)
-   Integração com Firebase (Backend Real).
-   Widget iOS (SwiftUI) lendo os arquivos locais compartilhados (App Group).
-   Push Notifications reais.
