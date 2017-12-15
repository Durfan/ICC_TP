#!/bin/bash

IMDBDIR=$1
OUTPUTDIR=$2

LOGO="ZEROUM - IMDB Extração e Manuseio"
amenu="(1) Pre-Processamento";
bmenu="(2) Verificar Pre-Processamento"; 
cmenu="(3) Extracao de dados"; 

invalida() { MSG="Opcao invalida..." ; }

pre() {
    clear
    cd $IMDBDIR
    echo ---------- PRE-PROCESSAMENTO ----------
    echo
    echo "\$Concatenado arquivos..."
    join -t $'\t' -o 2.1,2.2,2.3,2.4,2.5,2.6,2.7,2.8,2.9,1.2,1.3 title.ratings.tsv title.basics.tsv > ../$OUTPUTDIR/titles.tsv
    echo "\$Remover primeira linha do titles.tsv; gerar titles.all.tsv..."
    sed '1d' ../$OUTPUTDIR/titles.tsv > ../$OUTPUTDIR/titles.all.tsv
    cd ~-
    echo
    read -n 1 -s -r -p "Arquivos concatenados. Pressione qualquer tecla para continuar..."
}

verifica() {
    clear
    cd $OUTPUTDIR
    echo -e "#Linhas nos arquivos originais:"
    wc -l ../$IMDBDIR/title.basics.tsv
    wc -l ../$IMDBDIR/title.ratings.tsv
    echo -e "\n#Linhas nos arquivos gerados:"
    wc -l titles.tsv
    wc -l titles.all.tsv
    cd ~-
    echo
    read -n 1 -s -r -p "Pressione qualquer tecla para continuar..."
}

extrai() {
    clear
    cd $OUTPUTDIR
    echo  ----------- EXTRACAO -----------
    echo
    echo -e "01: \$sort \"titleType\" unicos\n"
    # Seleciona a coluna dois e usa pipe para organizar/selecionar os unicos na saida out1.txt
    cut -f 2 titles.all.tsv | sort | uniq | tee out1.txt

    echo -e "\n02: if \"primaryTitle\" e \"originalTitle\" iguais"
    # Compara as colunas 2 e 3, se forem iguais aumenta o contador, cria arquivo out2.txt com o numero de title iguais
    awk -F"\t" '{if ($3 == $4) s += 1} END{print s}' titles.all.tsv | tee out2.txt

    echo -e "\n03: \$media das avaliacoes entre 1970 e 2000"
    #C ompara se a coluna 6 está entre os valores (1970 a 2000), recebe em s a nota do filme, e em t a quantidade de filmes,
    # imprime em out3.txt a media das notas
    awk -F"\t" '{if (1969 < $6  && $6 < 2001){s += $10; t+= 1}} END{print s/t}' titles.all.tsv | tee out3.txt

    echo -e "\n04: \$media das avaliacoes entre 2000 e 2016"
    # Compara se a coluna 6 está entre os valores (2000 a 2016), recebe em s a nota do filme, e em t a quantidade de filmes,
    # imprime em out4.txt a media das notas
    awk -F"\t" '{if (1999 < $6  && $6 < 2017){s += $10; t+= 1}} END{print s/t}' titles.all.tsv | tee out4.txt

    echo -e "\n05: \$sort \"genres\" unicos existentes"
    # Separa a coluna 9 do arquivo, elimina (com grep -v) as linhas que possuem ',' e '\N', organiza (com sort) por ordem alfabetica,
    # elimina (com uniq) as entradas repetidas, conta as linhas com wc -l e imprime o numero de linhas no out5.txt
    cut -f 9 titles.all.tsv | grep -v "," | grep -v "\\N" | sort | uniq | wc -l | tr -d ' ' | tee out5.txt
    
    echo -e "\n06: \$titulos classificados como \"Action\""
    # Separa a coluna 9 do arquivo, separa todas linhas que possuem a palavra Action, conta as linhas e printa o numero em out6.txt
    cut -f 9 titles.all.tsv | grep "Action" | wc -l | tr -d ' ' | tee out6.txt
    
    echo -e "\n07: \$titulos \"Adventure\" produzidos desde 2005"
    awk -F"\t" '$9 ~ /Adventure/ && $6 != "\\N" && $6 >= 2005 {print $6,"\t",$9,"\t",$3}' titles.tsv | wc -l | tr -d ' ' | tee out7.txt

    echo -e "\n08: \$titulos \"Fantasy\" && \"Sci-Fi\" produzidos desde 2010"
    awk -F"\t" '{if ($9 ~ /Fantasy,Sci-Fi/ && $9 ~ /Sci-Fi/ && $6 != "\\N" && $6 >= 2010) print $6,"\t",$9,"\t",$3}' titles.tsv | wc -l | tr -d ' ' | tee out8.txt

    echo -e "\n09: \$razao de \"startYear=1970\" * total de titulos na base"
    echo -e "10: \$razao de \"startYear\" * total de titulos entre 1971 a 2016"

    echo -e "\n11: filmes com genero unico"
    # Separa a coluna 9, elimina as linhas que possuem ',' e '\N' sobrando somente os generos unicos e conta as linhas com wc -l
    cut -f 9 titles.all.tsv | grep -v "," | grep -v '\\N' | wc -l | tr -d ' ' | tee out11.txt

    echo -e "\n12: \$cinco \"genre\" com mais titulos"
    echo -e "13: \$media das avaliações por titulos > \"genero resultado\""
    echo -e "14: \$media das avaliações por titulos > \"genero resultado\" && \"numVotes\">100"
    echo -e "15: \$media das avaliações por tı́tulos > \"tipo resultado\""
    echo -e "16: \$imprimir razão de titulos * total com \"runtimeMinutes\" entre 80-120min"
    echo -e "17: \$+10 \"Action\" melhor avaliados desde 2005 \"titleType\"=movie && \"numVotes\">100"
    echo -e "18: \$+05 \"Comedy\" melhor avaliados com \"runtimeMinutes\">200min\n"
    echo -------- FIM DO EXTRACAO --------
    cd ~-
    echo
    read -n 1 -s -r -p "Pressione qualquer tecla para continuar..."
}

themenu () {
    clear
    echo `date`
    echo
    echo -e $LOGO
    echo
    echo -e $amenu
    echo -e $bmenu
    echo -e $cmenu
    echo -e "(4) Sair"
    echo
    echo $MSG
    echo
    echo Digite a opcao e pressione ENTER ;
}

MSG=
while true
    do
        themenu
        read answer
        MSG=
        case $answer in
        1) pre;;
        2) verifica;;
        3) extrai;;
        4) break;;
        *) invalida;;
    esac
done