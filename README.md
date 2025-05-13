# Onde abrir creches? Um exemplo de política pública baseada em evidências

Este repositório contém o código e os dados utilizados no projeto que visa identificar áreas prioritárias para a expansão da oferta de creches públicas na Região Metropolitana do Recife (RMR), com base em indicadores socioeconômicos e dados educacionais.

## 🧭 Objetivo

Contribuir para a tomada de decisão na gestão pública ao indicar, de forma georreferenciada, os locais com maior necessidade de expansão da educação infantil na modalidade creche (0 a 3 anos), utilizando dados como:

- Matrículas em creches por bairro ou setor censitário
- Número de crianças de 0 a 3 anos residentes na região
- Indicadores de vulnerabilidade social (IVS)
- Índice de Desenvolvimento Humano (IDHM)

## 📂 Estrutura do repositório

- `creches.R`: script principal de preparação dos dados.
- `creches_app.qmd`: relatório em Quarto com visualizações e análises interativas.
- `style_fun.R`: funções auxiliares de estilo e formatação.
- `arquivos/`: dados utilizados na análise (matrículas, população, IVS etc.).
- `shapes/`: arquivos geoespaciais utilizados para mapas.

## 💻 Como replicar o relatório

### 1. Pré-requisitos

Você precisa ter o R instalado (versão ≥ 4.2) com os seguintes pacotes:

```r
install.packages(c(
  "tidyverse", "sf", "readxl", "janitor", "ggplot2",
  "quarto", "ggtext", "geobr", "tmap", "glue"
))
```

Você também precisará instalar o Quarto:  
https://quarto.org/docs/get-started/

### 2. Clonar o repositório

```bash
git clone https://github.com/jpwa22/creches.git
cd creches
```

### 3. Rodar o script de dados

Abra o R ou RStudio e execute:

```r
source("creches.R")
```

Este script prepara os dados necessários e salva os objetos no formato apropriado para o relatório.

### 4. Gerar o relatório

No terminal ou RStudio, rode o seguinte comando:

```bash
quarto render creches_app.qmd
```

O relatório HTML será gerado na mesma pasta.

## 📊 Saída esperada

Um relatório com mapas temáticos, gráficos e tabelas interativas, identificando os bairros/setores censitários com maior necessidade de expansão do serviço de creche pública.

## 📌 Licença

Este projeto é distribuído sob a licença MIT.

## 🙋‍♂️ Autor

João Paulo Andrade 
[GitHub: @jpwa22](https://github.com/jpwa22)

---

*Para dúvidas ou sugestões, sinta-se à vontade para abrir uma issue ou entrar em contato.*
