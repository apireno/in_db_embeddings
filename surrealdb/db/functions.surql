

DEFINE FUNCTION OVERWRITE fn::mean_vector($vectors: option<array<array<float>>>) {
    
    IF $vectors IS NONE OR array::len($vectors) = 0 THEN {
        RETURN NONE; 
    }END;
    #remove any non-matches
    LET $vectors = array::filter($vectors, |$v| { RETURN $v != NONE; });

    IF $vectors IS NONE OR array::len($vectors) = 0 THEN {
        RETURN NONE; 
    }END;

    #normalize the vectors to ensure equal weighting to the tokens
    LET $normalized_vectors = $vectors.map(|$v| vector::normalize($v));

    #transpose the vectors to be able to average them
    LET $transposed = array::transpose($normalized_vectors);

    #sum up the individual floats in the arrays
    LET $sum_vector = $transposed.map(|$sub_array| math::sum($sub_array));

    # calculate the mean of each vector by dividing by the total number of 
    # vectors in each of the floats
    LET $mean_vector = vector::scale($sum_vector, 1.0 / array::len($normalized_vectors));

    #if the array size > 0
    RETURN IF $mean_vector.len() > 0 THEN $mean_vector ELSE NONE END;
};



DEFINE FUNCTION OVERWRITE fn::retrieve_vectors_for_text_with_oov($text:string) 
{
    LET $words = $text.lowercase().words();
    LET $words = $words[WHERE $this != ''];

    
    LET $all_vectors = (SELECT VALUE {'word':$this, 'embedding':type::thing("embedding_model",$this).embedding} FROM $words);
                    
    LET $matched_word_vectors =  (SELECT VALUE embedding FROM $all_vectors WHERE embedding IS NOT NONE);

    
    LET $unmatched_words = (SELECT VALUE {model:$model,word:word} FROM $all_vectors WHERE embedding IS NONE);

    LET $umatched_word_vectors = $unmatched_words.map(
        |$word|
        fn::mean_vector((SELECT VALUE embedding:[$word.model,$this].embedding FROM search::analyze("large_name_analyzer", $word.word))[WHERE $this IS NOT NONE])         
    
    )[WHERE $this IS NOT NONE];

    LET $vectors = $matched_word_vectors.concat($umatched_word_vectors);
        
    RETURN $vectors;

};



DEFINE FUNCTION OVERWRITE fn::content_to_vector($text: string) {
    IF $content_embedding_model IS NONE THEN
        RETURN NONE;
    END;
    LET $vectors = fn::retrieve_vectors_for_text_with_oov($text);
    RETURN fn::mean_vector($vectors);
};

   
DEFINE  FUNCTION OVERWRITE fn::remove_punctuation($input: string,$replace_with:"" | " ") -> string {

    LET $punctuation = [
        '.', ',', '&', '(', ')', '"', "'", "+", "!", '-', "{", "}", "[", "]", ":", ";", "<", ">", "`", "/", "\\", "—", "–"
    ];
    IF $replace_with = " " THEN{
        RETURN $punctuation.fold($input,|$a, $b| 
            $a.replace($b, " ")
        );
    }ELSE{
        RETURN $punctuation.fold($input,|$a, $b| 
            $a.replace($b, "")
        );
    }END;
};


