"""
Contém as funções utilizadas no contexto Exercício Prático 1 do Módulo 5 - Análise de dados no futebol com Python.

São apresentadas por ordem de utilização no notebook.
"""
import Imports as imps

# Função para otimizar data types
def auto_opt_pd_dtypes(df: imps.pd.DataFrame) -> imps.pd.DataFrame:
    """
    Converte automaticamente os data types numéricos para o mínimo possível. Não afeta outros data types (datetime, str, object, etc).
    Ignora colunas com missing values.
        
    Parâmetros:
    - df: Dataframe a ser otimizado.
    """
    df = df.copy()
        
    for col in df.columns:
        # números inteiros
        if issubclass(df[col].dtypes.type, imps.numbers.Integral):
            if df[col].min() >= 0:
                df[col] = imps.pd.to_numeric(df[col], downcast = "unsigned")
            else:
                df[col] = imps.pd.to_numeric(df[col], downcast = "integer")
        # números reais (floats)
        elif issubclass(df[col].dtypes.type, imps.numbers.Real):
            if df[col].notna().all() and (df[col] == df[col].astype(int)).all():
                df[col] = imps.pd.to_numeric(df[col], downcast = "integer")
            else:
                df[col] = imps.pd.to_numeric(df[col], downcast = "float")
    
    return df

# Função para exibir imagem a partir de URL
def image_from_url(ax, url):
    """
    Exibe uma imagem a partir de um URL.

    Parâmetros:
    - ax: Eixo do matplotlib onde a imagem será exibida.
    - url: URL da imagem a ser exibida.
    """
    if not isinstance(url, str):
        return

    with imps.urllib.request.urlopen(url) as u:
        img = imps.Image.open(u).convert("RGBA")
        ax.imshow(img)

    ax.axis("off")

# Função para criar tabelas customizadas com o package plottable
def plot_table(df: imps.pd.DataFrame,
               index_col: str,
               column_definitions: list,
               title: str,
               subtitle: str,
               logo: str,
               save_png: bool = False,
               png_name: str = "table.png"):
    """
    Cria uma tabela através do package plottable.

    Parâmetros:
    - df: Dataframe a ser exibido na tabela.
    - index_col: Coluna do dataframe a ser utilizada como índice.
    - column_definitions: Definições das colunas (lista de ColumnDefinition).
    - title: Título da tabela.
    - subtitle: Subtítulo da tabela.
    - logo: URL do logo a ser exibido na tabela.
    """
    fig, ax = imps.plt.subplots(figsize = (10, 11))
    fig.set_facecolor(imps.bg_color)
    ax.set_facecolor(imps.bg_color)

    # Tabela
    table = imps.Table(
        df,
        index_col = index_col,
        column_definitions = column_definitions,
        row_dividers = True,
        row_divider_kw = {"linewidth": 0.5, "color": "#7D7D7D"},
        footer_divider = True,
        textprops = {"fontsize": 10},
        ax = ax
    )

    # Título e subtítulo
    fig.subplots_adjust(top = 0.88)
    fig.text(
        0.12, 0.94,
        title,
        fontsize = 18,
        fontweight = "bold",
        ha = "left",
        va = "center",
        color = imps.text_color
    )
    fig.text(
        0.12, 0.91,
        subtitle,
        fontsize = 11,
        ha = "left",
        va = "center",
        color = "#313131"
    )

    # Logo da Bundesliga
    with imps.urllib.request.urlopen(logo) as url:
        logo_img = imps.Image.open(url).convert("RGBA")
    logo_array = imps.np.array(logo_img)
    logo_ax = fig.add_axes([0.03, 0.89, 0.06, 0.08])
    logo_ax.imshow(logo_array)
    logo_ax.axis("off")

    # Linha horizontal a separar o título do resto da tabela
    fig.add_artist(
        imps.plt.Line2D(
            [0.03, 0.97],
            [0.885, 0.885],
            transform = fig.transFigure,
            color = "#B0B0B0",
            linewidth = 0.6
        )
    )

    # Guardar imagem
    if save_png:
        fig.savefig(png_name, facecolor = fig.get_facecolor(), dpi = 200)

# Função para desenhar curvas coloridas entre pontos
def draw_curve(ax: imps.plt.Axes,
               x: list,
               y: list,
               color: str,
               lw: float = 4,
               alpha: float = 0.75):
    """
    Desenha uma curva colorida entre os pontos (x, y) no eixo ax.

    Parâmetros:
    - ax: Eixo do matplotlib onde a curva será desenhada.
    - x: Lista de coordenadas x dos pontos.
    - y: Lista de coordenadas y dos pontos.
    - color: Cor da curva.
    - lw: Largura da linha da curva.
    - alpha: Transparência da curva.
    """
    verts = [
        (x[0], y[0]),
        (x[0] + 0.4, y[0]),
        (x[1] - 0.4, y[1]),
        (x[1], y[1]),
        (x[1] + 0.4, y[1]),
        (x[2] - 0.4, y[2]),
        (x[2], y[2])
    ]

    codes = [
        imps.Path.MOVETO,
        imps.Path.CURVE4, imps.Path.CURVE4, imps.Path.CURVE4,
        imps.Path.CURVE4, imps.Path.CURVE4, imps.Path.CURVE4
    ]

    path = imps.Path(verts, codes)
    patch = imps.PathPatch(path, facecolor = "none", edgecolor = color, lw = lw, alpha = alpha)
    ax.add_patch(patch)

# Função para adicionar logo a partir de URL.
# Semelhante à função image_from_url, mas redimensiona a imagem para um tamanho fixo e permite posicionar em qualquer ponto do gráfico.
def add_logo_from_url(ax: imps.plt.Axes,
                      x: float,
                      y: float,
                      url: str,
                      px_size: int = 25):
    """
    Adiciona um logo a partir de um URL no ponto (x, y) do eixo ax.

    Parâmetros:
    - ax: Eixo do matplotlib onde o logo será adicionado.
    - x: Coordenada x do ponto onde o logo será adicionado.
    - y: Coordenada y do ponto onde o logo será adicionado.
    - url: URL do logo a ser adicionado.
    - px_size: Tamanho do logo em pixels (será redimensionado para este tamanho).
    """
    if not isinstance(url, str):
        return
    
    with imps.urllib.request.urlopen(url) as u:
        img = imps.Image.open(u).convert("RGBA")

    # Resize da imagem para um tamanho fixo (px_size x px_size)
    img = img.resize((px_size, px_size), imps.Image.LANCZOS)

    img_arr = imps.np.asarray(img)
    imagebox = imps.OffsetImage(img_arr, zoom = 1)
    ab = imps.AnnotationBbox(imagebox, (x, y), frameon = False, box_alignment = (0.5, 0.5))

    ax.add_artist(ab)

# Função para calcular e visualizar mapa de correlação de Spearman num heatmap e em tabela
def spearman_correlation(df: imps.pd.DataFrame,
                         numerical_variables: list) -> imps.pd.DataFrame:
    """
    Exibe um heatmap com a correlação de Spearman para as variáveis numéricas do dataset, e devolve uma tabela com as correlações entre todas as variáveis.

    Parâmetros:
    - df: Dataframe a ser analisado.
    - numerical_variables: Lista de variáveis numéricas a incluir na análise de correlação.
    """
    df = df.copy()

    cor = df[numerical_variables].corr("spearman")
    mask = imps.np.triu(imps.np.ones_like(cor, dtype = bool))

    imps.plt.figure(figsize = (12, 10))
    imps.sns.heatmap(data = cor,
                mask = mask,
                annot = True,
                annot_kws = {"size": 10},
                cmap = "vlag",
                vmax = 1,
                vmin = -1,
                center = 0,
                fmt = '.2')
    imps.plt.title("Spearman Correlation", y = 1.02)
    imps.plt.show()

    return cor