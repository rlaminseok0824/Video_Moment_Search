package main

import (
	"encoding/json"
	"fmt"
	"math"
	"sort"
)

type Output struct {
	Name     string    `json:"name"`
	Datatype string    `json:"datatype"`
	Shape    []int     `json:"shape"`
	Data     []float32 `json:"data"`
}

type Response struct {
	ModelName    string   `json:"model_name"`
	ModelVersion string   `json:"model_version"`
	Outputs      []Output `json:"outputs"`
}

func reshapeToFloat(data []float32, rows int, cols int) [][]float32 {
	if len(data) != rows*cols {
		return nil // 데이터 길이가 일치하지 않으면 nil을 반환합니다.
	}

	// fmt.Println(data)

	result := make([][]float32, rows)
	for i := 0; i < rows; i++ {
		result[i] = make([]float32, cols)
		for j := 0; j < cols; j++ {
			result[i][j] = data[i*cols+j]
		}
	}

	// fmt.Println(result)

	return result
}

func reshapeToInt(data []float32, rows int, cols int) [][]int32 {
	if len(data) != rows*cols {
		return nil // 데이터 길이가 일치하지 않으면 nil을 반환합니다.
	}

	result := make([][]int32, rows)
	for i := 0; i < rows; i++ {
		result[i] = make([]int32, cols)
		for j := 0; j < cols; j++ {
			if j%2 == 0 {
				result[i][j] = int32(data[i*cols+j])
			} else {
				result[i][j] = int32(math.Round(float64(data[i*cols+j])))
			}

		}
	}

	return result
}

func DecodeRawData(responseBody string) ([]float32, [][]int32, error) {
	response := new(Response)
	err := json.Unmarshal([]byte(responseBody), &response)
	if err != nil {
		return nil, nil, err
	}

	var logitsData, spansData []float32
	for _, output := range response.Outputs {
		if output.Name == "LOGITS" {
			logitsData = output.Data
		} else if output.Name == "SPANS" {
			spansData = output.Data
		}
	}

	if logitsData == nil || spansData == nil {
		return nil, nil, fmt.Errorf("missing LOGITS or SPANS data")
	}

	logits := reshapeToFloat(logitsData, 30, 2)
	score := LogittoScore(logits)
	fmt.Println(score)
	spans := reshapeToFloat(spansData, 30, 2)
	spans_int := SpanCxwToXx(spans)
	fmt.Println(spans_int)

	return score, spans_int, nil
}

func LogittoScore(logits [][]float32) []float32 {
	scores := make([]float32, len(logits))
	var sumExp float64

	// Extract the first column and compute exp
	for i, logit := range logits {
		expValue := float32(math.Exp(float64(logit[0])))
		scores[i] = expValue
		sumExp += float64(expValue)
	}

	// Normalize to get softmax probabilities
	for i := range scores {
		scores[i] = scores[i] / float32(sumExp)
	}

	return scores
}

func SpanCxwToXx(cxwSpans [][]float32) [][]int32 {
	result := make([][]int32, len(cxwSpans))
	for i, span := range cxwSpans {
		center := span[0]
		width := span[1]
		result[i] = []int32{int32((center - 0.5*width) * 150), int32((center + 0.5*width) * 150)}
	}
	return result
}

func CreateTritonBody(url string, text string) []byte {
	data := fmt.Sprintf(`{
			"name": "string_identity",
					"inputs": [
						{
							"name": "INPUT0",
							"shape": [1],
							"datatype": "BYTES",
							"data": ["%s"]
						},
						{
							"name": "INPUT1",
							"shape": [1],
							"datatype": "BYTES",
							"data": ["%s"]
						}
					]
    }`, url, text)

	tritonData := []byte(data)

	return tritonData
}

// func Combine(logits [][]float32, spans [][]int32, threshold float32) [][]float32 {
// 	var combined [][]float32

// 	for i := 0; i < len(logits); i++ {
// 		// logits의 첫번째 값의 확률이 threshold보다 크면 combined에 추가
// 		if logits[i][0] > threshold {
// 			combinedRow := []float32{
// 				float32(spans[i][0]),
// 				float32(spans[i][1]),
// 				roundToOneDecimalPlace(logits[i][0]),
// 			}
// 			if combinedRow[0] != combinedRow[1] {
// 				combined = append(combined, combinedRow)
// 			}
// 		}
// 	}

// 	return combined
// }

// func Combine(logits []float32, spans [][]int32, threshold float32) [][]float32 {
// 	fmt.Println(logits)
// }

func CombineAndSort(spans [][]int32, scores []float32) [][3]int {
	combined := make([][3]int, len(spans))
	for i, span := range spans {
		combined[i] = [3]int{int(span[0]), int(span[1]), int(scores[i] * 1000)} // Multiply score by 1000 and convert to int for easier handling
	}

	// Sort combined array based on scores
	sort.Slice(combined, func(i, j int) bool {
		return combined[i][2] > combined[j][2] // Compare scores
	})

	return combined
}

func roundToOneDecimalPlace(value float32) float32 {
	rounded := float32(math.Round(float64(value)*10) / 10)
	if rounded == 1.0 {
		rounded = 0.9
	}
	return rounded
}

func ToString(combined [][3]int) string {
	result := ""
	for _, row := range combined {
		result += fmt.Sprintf(`["%d", "%d", "%d"] `, row[0], row[1], row[2])
	}

	return result
}
