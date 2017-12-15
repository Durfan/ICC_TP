#!/bin/bash

IMDBDIR=$1
OUTPUTDIR=$2

LOGO="ZEROUM - IMDB Extração e Manuseio"
amenu="(1) Pre-Processamento";
bmenu="(2) Verificar Pre-Processamento"; 
cmenu="(3) Extracao de dados";
dmenu="(4) Ver dados extraidos"; 

invalida() { MSG="Opcao invalida..." ; }

themenu () {
    clear
    echo `date`
    echo
    echo -e $LOGO
    echo
    echo -e $amenu
    echo -e $bmenu
    echo -e $cmenu
    echo -e $dmenu
    echo -e "(5) Sair"
    echo
    echo $MSG
    echo
    echo Digite a opcao e pressione ENTER ;
}

pre() {
    START_TIME=$SECONDS
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
    ELAPSED_TIME=$(($SECONDS - $START_TIME))
    echo Tempo gasto na execucao: $ELAPSED_TIME"s"
    echo
    echo ------ FIM DO PRE-PROCESSAMENTO -------
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
    START_TIME=$SECONDS
    clear
    cd $OUTPUTDIR
    echo  ----------- EXTRACAO -----------
    echo
    echo 01: \"titleType\" unicos
    echo
    cut -f 2 titles.all.tsv | sort | uniq | tee out1 # Seleciona a coluna dois e usa pipe para organizar/selecionar os unicos na saida out1.txt
    echo
    echo 02: \"primaryTitle\" e \"originalTitle\" iguais
    awk -F"\t" '{if ($3 == $4) s += 1} END{print s}' titles.all.tsv | tee out2 # Compara as colunas 2 e 3, se forem iguais aumenta o contador, cria arquivo out2.txt com o numero de title iguais
    echo
    echo 03: media das avaliacoes entre 1970 e 2000 
    awk -F"\t" '{if (1969 < $6  && $6 < 2001){s += $10; t+= 1}} END{printf("%.4f\n", s/t)}' titles.all.tsv | tee out3 # Compara se a coluna 6 está entre os valores (1970 a 2000), recebe em s a nota do filme, e em t a quantidade de filmes, imprime em out3.txt a media das notas
    echo
    echo 04: media das avaliacoes entre 2000 e 2016  
    awk -F"\t" '{if (1999 < $6  && $6 < 2017){s += $10; t+= 1}} END{printf("%.4f\n", s/t)}' titles.all.tsv | tee out4 # Compara se a coluna 6 está entre os valores (2000 a 2016), recebe em s a nota do filme, e em t a quantidade de filmes, imprime em out4.txt a media das notas
    echo
    echo 05: generos unicos
    cut -f 9 titles.all.tsv | grep -v "," | grep -v "\\N" | sort | uniq | wc -l | tr -d ' ' | tee out5 # Separa a coluna 9 do arquivo, elimina (com grep -v) as linhas que possuem ',' e '\N', organiza (com sort) por ordem alfabetica, elimina (com uniq) as entradas repetidas, conta as linhas com wc -l e imprime o numero de linhas no out5.txt
    echo
    echo 06: titulos classificados como \"Action\"
    cut -f 9 titles.all.tsv | grep "Action" | wc -l | tr -d ' ' | tee out6 # Separa a coluna 9 do arquivo, separa todas linhas que possuem a palavra Action, conta as linhas e printa o numero em out6.txt
    echo
    echo 07: titulos \"Adventure\" produzidos desde 2005
    awk -F"\t" '$9 ~ /Adventure/ && $6 != "\\N" && $6 >= 2005 {print $6,"\t",$9,"\t",$3}' titles.all.tsv | sort | wc -l | tr -d ' ' | tee out7
    echo
    echo 08: titulos \"Fantasy\" e \"Sci-Fi\" produzidos desde 2010
    awk -F"\t" '{if (($9 ~ /Fantasy/ || $9 ~ /Sci-Fi/) && ($6 != "\\N" && $6 >= 2010)) print $6,"\t",$9,"\t",$3}' titles.all.tsv | sort | wc -l | tr -d ' ' | tee out8

    echo -e "\n09: razao de \"startYear=1970\" * total de titulos na base"
    echo -e "10: razao de \"startYear\" * total de titulos entre 1971 a 2016"

    echo -e "\n11: filmes com genero unico"
    # Separa a coluna 9, elimina as linhas que possuem ',' e '\N' sobrando somente os generos unicos e conta as linhas com wc -l
    cut -f 9 titles.all.tsv | grep -v "," | grep -v '\\N' | wc -l | tr -d ' ' | tee out11

    echo -e "\n12: cinco generos com mais titulos"
    echo -e "13: media das avaliacoes por titulos > \"genero resultado\""
    echo -e "14: media das avaliacoes por titulos > \"genero resultado\" && numVotes>100"
    echo -e "15: media das avaliacoes por tı́tulos > \"tipo resultado\""
    echo -e "16: razao de titulos * total com \"runtimeMinutes\" entre 80-120min"
    echo -e "17: dez \"Action\" melhor avaliados desde 2005 titleType=movie && numVotes>100"
    echo -e "18: cinco \"Comedy\" melhor avaliados com runtimeMinutes>200min\n"
    echo
    ELAPSED_TIME=$(($SECONDS - $START_TIME))
    echo Tempo gasto na execucao: $ELAPSED_TIME"s"
    echo
    echo -------- FIM DO EXTRACAO --------
    cd ~-
    echo
    read -n 1 -s -r -p "Pressione qualquer tecla para continuar..."
}

imprime() {
    clear
    cd $OUTPUTDIR
    echo " Item 1"
    echo ---------------
    cat out1
    echo ---------------
    echo -n " Item 2: "; cat out2
    echo -n " Item 3: "; cat out3
    echo -n " Item 4: "; cat out4
    echo -n " Item 5: "; cat out5
    echo -n " Item 6: "; cat out6
    echo -n " Item 7: "; cat out7
    echo -n " Item 8: " ; cat out8
    echo -n "Item 11: "; cat out11
    cd ~-
    echo
    read -n 1 -s -r -p "Pressione qualquer tecla para continuar..."
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
        4) imprime;;
        5) break;;
        *) invalida;;
    esac
done