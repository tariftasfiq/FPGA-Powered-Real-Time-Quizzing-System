/*
Implementing Quizzing System
Optional task: There will be a button for manual/auto, in auto mode reset will happen automatically after 15s
1. code for team selection, among 4 teams, 1st team will be selected
2. when a team will press the buzzer, following things will initiate:
	a. a timer will turn on for 10s and show time count on 7 seg display
	b. selected team will be seen in the dot matrix
	c. after 10s, timeup led will lit up, then second led will lit for 5s for the judge to press answer
	d. system will automatically reset after the 15s
3. there will be a button to indicate finish, when finished button is pressed, result will be shown
*/

module quizzing_system(
	input clk,
	input master_reset,
	input reset,
	input teamA,
	input teamB,
	input teamC,
	input teamD,
	input correct,
	input end_quiz,
	inout led_com,
	output reg [6:0] seg,
	output reg [7:0] row,
	output reg [7:0] col,
	output reg timeup,
	output reg judging_time,
	output reg [3:0] active_team,
	output reg [3:0] winner_team,
	output [3:0] winner_score,
	output reg buzzer_locked
);
	assign led_com = 1;
	// reg buzzer_locked;
    reg [3:0] count;      // 4-bit counter for 0 to 10
    reg [23:0] clk_div;   // Clock divider for 1Hz signal
    reg [4:0] judging_counter; // Counter for judging time (5s)
    reg [4:0] total_time_counter; // Counter for total time (15s)
    reg [3:0] bcd;
    reg [3:0] scoreA;
    reg [3:0] scoreB;
    reg [3:0] scoreC;
    reg [3:0] scoreD;
	reg start_next_round;
	reg [7:0] state [7:0];
	reg show_score;
	reg update_score;
    
    // initial block
    
    initial begin 
	buzzer_locked = 0;
	start_next_round = 1;
	show_score = 0;
	scoreA = 0;
	scoreB = 0;
	scoreC = 0;
	scoreD = 0;
	winner_team = 0;
	update_score = 0;
    
    // here apply priority encoder logic
    
    end
// buzzer_locked block
	always @(posedge clk) begin
		if(master_reset) begin
			active_team <= 4'b0000;
			buzzer_locked <= 0;
			update_score <=0;
			clk_div <= 0;
            count <= 0;
            timeup <= 0;
            judging_time <= 0;
            judging_counter <= 0;
            total_time_counter <= 0;
			scoreA <= 0;
			scoreB <= 0;
			scoreC <= 0;
			scoreD <= 0;
			bcd <= 0;
		end else if(reset) begin
			active_team <= 4'b0000;
			buzzer_locked <= 0;
			update_score <=0;
			clk_div <= 0;
            count <= 0;
            timeup <= 0;
            judging_time <= 0;
            judging_counter <= 0;
            total_time_counter <= 0;
			bcd <= 0;
		end else if(buzzer_locked) begin // it will be 1
            if (clk_div == 24'd5_000_000) begin // For 10MHz clock to 1Hz
                clk_div <= 0;
				count <= count + 1;
				if(timeup == 0)
					bcd <= count;
				
				if(count == 10) begin
					timeup <= 1;
					// bcd <= 5;
				end
         
            end else begin
                clk_div <= clk_div + 1;
            end
        end
		if(timeup && end_quiz == 0) begin
				case(active_team)
					4'b0001: bcd <= scoreA;
					4'b0010: bcd <= scoreB;
					4'b0100: bcd <= scoreC;
					4'b1000: bcd <= scoreD;
					default: bcd <= 0;
				endcase
		end 
		if(end_quiz) begin
		
			if(scoreA > scoreB && scoreA > scoreC && scoreA > scoreD)
				begin
					bcd <= scoreA;
					active_team <= 4'b0001;
				end
			else if (scoreB> scoreA && scoreB > scoreC && scoreB > scoreD)
				begin
					bcd <= scoreB;
					active_team <= 4'b0010;
				end
			else if (scoreC > scoreA && scoreC > scoreB && scoreC > scoreD)
				begin
					bcd <= scoreC;
					active_team <= 4'b0100;
				end
			else if (scoreD > scoreA && scoreD > scoreB && scoreD > scoreC)
				begin
					bcd <= scoreD;
					active_team <= 4'b1000;
				end
			else bcd <= 0;
		end
		if(buzzer_locked == 0 && timeup == 0) begin
			if(teamA) begin
				active_team <= 4'b0001;
				buzzer_locked <= 1;
			end else if(teamB) begin
				active_team <= 4'b0010;
				buzzer_locked <= 1;
			end else if(teamC) begin
				active_team <= 4'b0100;
				buzzer_locked <= 1;
			end else if(teamD) begin
				active_team <= 4'b1000;
				buzzer_locked <= 1;
			end 
		end
		
		if(correct && buzzer_locked) begin // remove update_score
			case(active_team)
				4'b0001: scoreA <= scoreA + 1;
				4'b0010: scoreB <= scoreB + 1;
				4'b0100: scoreC <= scoreC + 1;
				4'b1000: scoreD <= scoreD + 1;
			endcase
			//update_score <= 0;
			buzzer_locked <=0;
		end
end


    // 7-segment display 
    always @(*) begin
        case (bcd)
            4'd0: seg = 7'b1111110; // 0
            4'd1: seg = 7'b0110000; // 1
            4'd2: seg = 7'b1101101; // 2
            4'd3: seg = 7'b1111001; // 3
            4'd4: seg = 7'b0110011; // 4
            4'd5: seg = 7'b1011011; // 5
            4'd6: seg = 7'b1011111; // 6
            4'd7: seg = 7'b1110000; // 7
            4'd8: seg = 7'b1111111; // 8
            4'd9: seg = 7'b1111011; // 9
            4'd10: seg = 7'b1111110; // Display 0 when count is 10
            default: seg = 7'b0000000; // Blank
        endcase
    end

	// dot matrix
	reg [1:0] count_1;       // Counter for falling clock
    // reg [7:0] state [7:0];    // 8x8 matrix representing stored blocks
    reg [2:0] scan_row;       // Current row being scanned for display
    reg clk_0;                // Clock output for button speed
    reg [7:0] clk_1;

    initial begin
        clk_1=8'b00000000;            // Initialize clock divider output
        scan_row = 0;
    end


	always @(posedge clk) begin	
		case(active_team)
		4'b0001: begin
				state[0] = 8'b01000000;
				state[1] = 8'b11000000;
				state[2] = 8'b01000000;
				state[3] = 8'b01000000;
				state[4] = 8'b00000000;
				state[5] = 8'b00000000;
				state[6] = 8'b00000000;
				state[7] = 8'b00000000;
				end
		4'b0010: begin
				state[0] = 8'b00000111;
				state[1] = 8'b00000011;
				state[2] = 8'b00000110;
				state[3] = 8'b00000111;
				state[4] = 8'b00000000;
				state[5] = 8'b00000000;
				state[6] = 8'b00000000;
				state[7] = 8'b00000000;
				end
		 4'b0100: begin
				state[0] = 8'b00000000;
				state[1] = 8'b00000000;
				state[2] = 8'b00000000;
				state[3] = 8'b11100000;
				state[4] = 8'b00100000;
				state[5] = 8'b11100000;
				state[6] = 8'b00100000;
				state[7] = 8'b11100000;
				end
		4'b1000: begin
				state[0] = 8'b00000000;
				state[1] = 8'b00000000;
				state[2] = 8'b00000000;
				state[3] = 8'b00000000;
				state[4] = 8'b00000101;
				state[5] = 8'b00000101;
				state[6] = 8'b00000111;
				state[7] = 8'b00000001;
				end
		default: begin
				state[0] = 8'b00000000;
				state[1] = 8'b00000000;
				state[2] = 8'b00000000;
				state[3] = 8'b00000000;
				state[4] = 8'b00000000;
				state[5] = 8'b00000000;
				state[6] = 8'b00000000;
				state[7] = 8'b00000000;
		end
			
		endcase 
end

	   // Display control
	always @(posedge clk) begin
        // Scanning through each row
		if(&clk_1) begin
			row <= 1 << scan_row;   // Active low row select
			col <= state[scan_row];    // Output the corresponding pattern for the selected row

			// Increment scan_row for next row
			scan_row <= scan_row + 1;
		end
		clk_1 <= clk_1+1;
		end

endmodule


	

	