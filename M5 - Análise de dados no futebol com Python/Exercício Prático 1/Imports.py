"""
Descrição: Contém as importações necessárias para o Exercício Prático 2 do Módulo 5 - Análise de dados no futebol com Python.
"""
import numpy as np
import pandas as pd
#from tqdm.notebook import tqdm
import requests
import json
import numbers

from PIL import Image
import urllib
import matplotlib
from matplotlib.offsetbox import OffsetImage, AnnotationBbox
from matplotlib.path import Path
from matplotlib.patches import PathPatch
import matplotlib.pyplot as plt
from plottable import Table, ColumnDefinition
from plottable.cmap import normed_cmap
from plottable.plots import image
import seaborn as sns

bg_color = "#F7F2E9"
text_color = "#000000"

plt.rcParams["text.color"] = text_color
plt.rcParams["font.family"] = "Segoe UI"

import warnings
warnings.filterwarnings("ignore")

pd.set_option("display.max_columns", None)
pd.set_option("display.max_rows", None)