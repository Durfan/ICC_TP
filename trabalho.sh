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
#Seleciona a coluna dois e pipe para organizar e selecionar os unicos na saida out1.txt
cut -f 2 titles.all.tsv | sort | uniq > out1.txt

echo "02:if \"primaryTitle\" e \"originalTitle\" iguais"
echo "03:media das avaliacoes entre 1970 e 2000"
echo "04:media das avaliacoes entre 2000 e 2016"
echo "05:sort \"genres\" unicos existentes"
echo "06:titulos classificados como \"Action\""
echo "07:titulos \"Adventure\" produzidos desde 2005"
echo "08:titulos \"Fantasy\" && \"Sci-Fi\" produzidos desde 2010"
echo "09:razao de \"startYear=1970\" * total de titulos na base"
echo "10:razao de \"startYear\" * total de titulos entre 1971 a 2016"
echo "11:filmes com genero unico"
echo "12:cinco \"genre\" com mais titulos"
echo "13:media das avaliações por seus titulos--> \"genero resultado\""
echo "14:media das avaliações por seus titulos--> \"genero resultado\" && \"numVotes\">100"
echo "15:media das avaliações por seus tı́tulos--> \"tipo resultado\""
echo "16:imprime razão de titulos * total com \"runtimeMinutes\" entre 80-120min"
echo "17:+10 \"Action\" melhor avaliados desde 2005 \"titleType\"=movie && \"numVotes\">100"
echo "18:+05 \"Comedy\" melhor avaliados com \"runtimeMinutes\">200min"
echo -e "\n-------- FIM DO PROCESSAMENTO --------\n"
cd ~-
