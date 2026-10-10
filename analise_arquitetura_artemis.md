# Arquitetura e Funcionamento do Sistema Artemis

Este documento é a base estruturada para a sua apresentação. Ele detalha a arquitetura atual e a visão de futuro, os papéis do Model Context Protocol (MCP) e o fluxo de chamadas do sistema Artemis.

## 1. Visão Geral da Arquitetura
ef
O **Artemis** é um ecossistema projetado com um forte isolamento de responsabilidades, combinando Inteligência Artificial (usando modelos locais para privacidade) com um padrão de integração moderno, o **Model Context Protocol (MCP)**. A arquitetura adota estritamente os papéis definidos pelo padrão MCP (Host, Client, Server), permitindo a expansão modular para múltiplos domínios de negócio.

Os componentes principais são organizados nos seguintes papéis:

### MCP Host & Client (Cérebro e Orquestração)
1. **Artemis Front (Angular 18):** Interface com o usuário, de onde partem as requisições de chat.
2. **Artemis API (Spring Boot + Spring AI):** O "Cérebro" orquestrador da plataforma.
   - Atua como **MCP Host**: Gerencia a sessão do chat, interage com a LLM (Ollama) exclusivamente para reconhecimento de intenção e decide quais ações tomar.
   - Atua como **MCP Client**: Descobre e se conecta dinamicamente aos diversos servidores MCP (via SSE/JSON-RPC) para acionar as "Tools".

### MCP Servers & APIs de Domínio
A plataforma é desenhada para suportar múltiplos domínios de negócio de forma isolada. Cada domínio possui seu próprio **MCP Server** e **Domain API**:

* **Domínios Atuais (Já Desenvolvidos):**
  3. **Módulo RH:**
     - **Artemis MCP RH (Go):** Atua como **MCP Server**. Expõe as ferramentas de Recursos Humanos e monta requisições dinâmicas.
     - **Artemis RH API (Spring Boot):** Microsserviço de domínio com filtros dinâmicos via `Specification`.
     - **PostgreSQL (postgres-rh):** Banco de dados isolado.
  4. **Módulo UserMan (Gestão de Usuários):**
     - **Artemis MCP UserMan (Go):** Expõe ferramentas de busca de perfis e bloqueio de acesso (com suporte SSE e stdio).
     - **Artemis UserMan API (Spring Boot):** Microsserviço de domínio focado na gestão de acessos e roles. Usa Flyway para migrations.
     - **PostgreSQL (postgres-userman):** Banco de dados isolado.
  5. **Módulo Frotas:**
     - **Artemis MCP Frotas (Go):** Adapta a inteligência para um esquema de Graph. Constrói e dispara Queries e Mutations automaticamente baseando-se no request da IA.
     - **Artemis Frotas API (Spring Boot):** Microsserviço construído com **Spring GraphQL**, oferecendo endpoints flexíveis e tipados.

* **Novos Domínios (Pipeline de Evolução):**
  A mesma estrutura será replicada gradualmente para:
  - **Formulários:** Gestão de fluxos de formulários.
  - **SGIE (Sistema de Eleições):** Criação de eleições, zonas, locais de votação, etc.

---

## 2. Diagrama de Fluxo de Comunicação (Multi-Domínio)

```mermaid
flowchart TD
    User([Usuário]) -->|Chat| Front(Artemis Front - Angular)
    Front -->|POST /api/chat| CoreAPI(Artemis API - Spring Boot\n[MCP Host & Client])
    
    subgraph Core System [Inteligência e Orquestração]
        CoreAPI -->|1. Orquestração (Planner)| LLM(Ollama Local / Spring AI)
        LLM -->|Retorna Plan (JSON)| CoreAPI
        CoreAPI -->|2. Validação/Execução| Rules(Execution & Policy)
    end
    
    subgraph Integration Layer [MCP Servers]
        CoreAPI -->|3. SSE/JSON-RPC| MCP_RH(MCP RH - Go)
        CoreAPI -->|3. SSE/JSON-RPC| MCP_UserMan(MCP UserMan - Go)
        CoreAPI -->|3. SSE/JSON-RPC| MCP_Frotas(MCP Frotas - Go)
        CoreAPI -.->|Pipeline| MCP_Formularios(MCP Formulários)
    end
    
    subgraph Domain Layer [Domínios de Negócio Isolados]
        MCP_RH -->|4. REST (Filtros Dinâmicos)| RH_API(RH API)
        MCP_UserMan -->|4. REST| UserMan_API(UserMan API)
        MCP_Frotas -->|4. GraphQL (Query/Mutation)| Frotas_API(Frotas API)
        
        RH_API --> DB_RH[(DB RH)]
        UserMan_API --> DB_UserMan[(DB UserMan)]
        Frotas_API --> DB_Frotas[(DB Frotas)]
    end
```

---

## 3. Passo a Passo: O Fluxo de uma Requisição (Orquestração Multi-Agente)

Quando o usuário envia uma mensagem, o fluxo atravessa um pipeline robusto no Host:

1. **Entrada e Planejamento (`PlannerService`):** O sistema recupera a memória da conversa. O orquestrador usa a IA para analisar o texto e gerar um **Plano de Ação** (`Plan`) com passos explícitos indicando o domínio (ex: RH) e os parâmetros extraídos, agindo como um Arquiteto de Solução.
2. **Resolução de Entidades e Especialistas (`EntityResolverService` & `SpecialistService`):** Se a ação exigir IDs específicos, o sistema invoca ferramentas internas para mapear nomes para IDs. O `SpecialistService` atua como um mapeador inteligente que decide exatamente qual ferramenta invocar, guiando-se pelos schemas das ferramentas.
3. **Execução via MCP Client (`ExecutionService` & `SseMcpClient`):** O sistema dispara a requisição JSON-RPC via SSE para o servidor Go correspondente ao domínio. 
4. **Integração Dinâmica com o Domínio (A Regra do REST Dinâmico):** Os servidores MCP recebem os comandos e constroem consultas otimizadas. No caso do RH, ao invés de buscar toda a base ou de criar dezenas de rotas, o servidor Go envia as variáveis da IA como parâmetros de Query String (ex: `?cargo=X&nome=Y`). A API Java usa **Spring Data Specifications** para montar a query SQL dinamicamente no banco, unindo a flexibilidade parecida com o GraphQL sem adicionar sua complexidade.
5. **Síntese e Retorno (`FinalSummarizerService`):** Os resultados brutos das APIs são unificados. A IA entra novamente em ação apenas para interpretar os dados (ex: JSONs ou confirmações) e escrever uma resposta em linguagem natural e amigável que é devolvida ao Front-End.

---

## 4. Regras e Princípios Chave (Destaques para a Apresentação)

* **Clareza nos Papéis MCP:** A arquitetura divide responsabilidades: a API Artemis dita o ritmo (Host) e se conecta aos provedores de recursos (Servers MCP).
* **Prevenção de "Endpoint Sprawl" (Filtros Dinâmicos):** Para evitar a explosão de múltiplos endpoints nos controladores das APIs de domínio, adota-se o padrão REST dinâmico com **Spring Data Specifications**. Os MCP Servers encapsulam a chamada e passam os filtros na query string, otimizando processamento e uso de tokens.
* **Escalabilidade Multi-Domínio (Plug and Play):** Novos domínios (Formulários, SGIE, Frotas) podem ser inseridos acionando apenas um novo servidor MCP, sem precisar de refatoração do orquestrador central.
* **Orquestração Multi-Passos (Plan & Execute):** A adoção de um *Planner* permite que tarefas compostas sejam quebradas em etapas (ex: buscar ID de usuário e depois bloquear o perfil).
* **IA Determinística e Limitada:** A Inteligência Artificial serve estritamente para compreender intenções, montar o planejamento e redigir a resposta final. A execução e a validação de regras de negócio são exclusivas do código (`ExecutionService` e as `Domain APIs`).
* **Isolamento de Dados:** Cada módulo obedece ao padrão de microsserviços possuindo sua própria base de dados.
