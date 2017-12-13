#!/bin/bash

IMDBDIR=$1
OUTPUTDIR=$2

#pre-processamento ---------------

cd $IMDBDIR
echo -e "\n---------- PRE-PROCESSAMENTO ----------\n"
echo -e "#Linhas arquivos originais:"
wc -l title.basics.tsv
wc -l title.ratings.tsv
echo -e "\n:Concatenado arquivos...\n"
join -t $'\t' -o 2.1,2.2,2.3,2.4,2.5,2.6,2.7,2.8,2.9,1.2,1.3 title.ratings.tsv title.basics.tsv > ../$OUTPUTDIR/titles.tsv
cd ~-

cd $OUTPUTDIR
echo "#Linhas no arquivo gerado:"
wc -l titles.tsv
echo -e "\n:Remover primeira linha do titles.tsv; gerar titles.all.tsv..."
sed '1d' titles.tsv > titles.all.tsv
echo -e "\n#Linhas no arquivo gerado:"
wc -l titles.all.tsv

#fim do pre-processamento----------

echo -e "\n----------- PROCESSAMENTO -----------\n"

echo "01:sort \"titleType\" unicos"
#Seleciona a coluna dois e usa pipe para organizar/selecionar os unicos na saida out1.txt
cut -f 2 titles.all.tsv | sort | uniq > out1.txt

echo "02:if \"primaryTitle\" e \"originalTitle\" iguais"
#Compara as colunas 2 e 3, se forem iguais aumenta o contador, cria arquivo out2.txt com o numero de title iguais
awk -F"\t" '{if ($3 == $4) s += 1}END{print s}' titles.all.tsv > out2.txt

echo "03:media das avaliacoes entre 1970 e 2000"
#Compara se a coluna 6 está entre os valores (1970 a 2000), recebe em s a nota do filme, e em t a quantidade de filmes, imprime em out3.txt a media das notas
awk -F"\t" '{if (1969 < $6  && $6 < 2001){s += $10; t+= 1}}END{print s/t}' titles.all.tsv > out3.txt

echo "04:media das avaliacoes entre 2000 e 2016"
#Compara se a coluna 6 está entre os valores (2000 a 2016), recebe em s a nota do filme, e em t a quantidade de filmes, imprime em out4.txt a media das notas
awk -F"\t" '{if (1999 < $6  && $6 < 2017){s += $10; t+= 1}}END{print s/t}' titles.all.tsv > out4.txt

echo "05:sort \"genres\" unicos existentes"
#Separa a coluna 9 do arquivo, elimina (com grep -v) as linhas que possuem ',' e '\N', organiza (com sort) por ordem alfabetica, elimina (com uniq) as entradas repetidas, conta as linhas com wc -l e imprime o numero de linhas no out5.txt
cut -f9 titles.all.tsv|grep -v ","|grep -v '\\N' | sort | uniq | wc -l > out5.txt

echo "06:titulos classificados como \"Action\""
#Separa a coluna 9 do arquivo, separa todas linhas que possuem a palavra Action, conta as linhas e printa o numero em out6.txt
cut -f9 titles.all.tsv|grep "Action"| wc -l > out6.txt

echo "07:titulos \"Adventure\" produzidos desde 2005"
echo "08:titulos \"Fantasy\" && \"Sci-Fi\" produzidos desde 2010"
echo "09:razao de \"startYear=1970\" * total de titulos na base"
echo "10:razao de \"startYear\" * total de titulos entre 1971 a 2016"

echo "11:filmes com genero unico"
#Separa a coluna 9, elimina as linhas que possuem ',' e '\N' sobrando somente os generos unicos e conta as linhas com wc -l
cut -f9 titles.all.tsv|grep -v ","|grep -v '\\N' | wc -l

echo "12:cinco \"genre\" com mais titulos"
echo "13:media das avaliações por seus titulos--> \"genero resultado\""
echo "14:media das avaliações por seus titulos--> \"genero resultado\" && \"numVotes\">100"
echo "15:media das avaliações por seus tı́tulos--> \"tipo resultado\""
echo "16:imprime razão de titulos * total com \"runtimeMinutes\" entre 80-120min"
echo "17:+10 \"Action\" melhor avaliados desde 2005 \"titleType\"=movie && \"numVotes\">100"
echo "18:+05 \"Comedy\" melhor avaliados com \"runtimeMinutes\">200min"
echo -e "\n-------- FIM DO PROCESSAMENTO --------\n"
cd ~-
