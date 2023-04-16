local function org_drill_modify_e_factor(ef, quality)
	-- Return new e-factor given existing EF and QUALITY."
	if ef < 1.3 then
		return 1.3
	else
		return ef + (0.1 - ((5 - quality) * (0.08 + ((5 - quality) * 0.02))))
	end
end

local function sign(n)
	if n == 0 then
		return 0
	elseif n > 0 then
		return 1
	else
		return -1
	end
end

-- Returns a random number between 0.5 and 1.5.
-- This returns a strange random number distribution. See
-- http://www.evidence.com/english/ol/sm5.htm for details."
local function org_drill_random_dispersal_factor()
	local a = 0.047
	local b = 0.092
	local p = math.random() - 0.5
	return (100 + (-1 / b) * math.log(1 - ((b / a) * math.abs(p))) * sign(p)) / 100.0
end

local org_drill_add_random_noise_to_intervals_p = true

local org_drill_adjust_intervals_for_early_and_late_repetitions_p = true

local org_drill_failure_quality = 2

local org_drill_sm5_initial_interval = 4.0

local org_drill_learn_fraction = 0.5

local function org_drill_round_float(floatnum, fix)
	local n = math.pow(10, fix or 0)
	return math.floor(floatnum * n + 0.5) / n
end

local function org_drill_initial_optimal_factor_sm5(n, ef)
	if n == 1 then
		return org_drill_sm5_initial_interval
	else
		return ef
	end
end

local function org_drill_get_optimal_factor_sm5(n, ef, of_matrix)
	--  print("org_drill_get_optimal_factor_sm5")
	--  print(vim.inspect(of_matrix))
	--print("org_drill_get_optimal_factor_sm5<<<<<<<<")
	--print(vim.inspect(n))
	--print(vim.inspect(ef))
	--print(vim.inspect(of_matrix))
	if of_matrix and of_matrix[n] and of_matrix[n][ef] then
		return of_matrix[n][ef]
	else
		return org_drill_initial_optimal_factor_sm5(n, ef)
	end
end

local function org_drill_set_optimal_factor(n, ef, of_matrix, of)
	--print("org_drill_set_optimal_factor<<<")
	--print(vim.inspect(of_matrix))
	if of_matrix and of_matrix[n] then
		of_matrix[n][ef] = of
	else
		if not of_matrix then
			of_matrix = {}
		end
		of_matrix[n] = { [ef] = of }
	end
	--print(vim.inspect(of_matrix))
	--print("org_drill_set_optimal_factor>>>")
	return of_matrix
end

local function org_drill_inter_repetition_interval_sm5(last_interval, n, ef, of_matrix)
	local of = org_drill_get_optimal_factor_sm5(n, ef, of_matrix)
	if n == 1 then
		return of
	else
		return of * last_interval
	end
end

local function org_drill_early_interval_factor(optimal_factor, optimal_interval, days_ahead)
	local delta_ofmax = (1 - optimal_factor)
		* (optimal_interval + (0.6 * optimal_interval) - 1)
		/ (1 - optimal_interval)
	return optimal_factor - (delta_ofmax * (days_ahead / (days_ahead + (0.6 * optimal_interval))))
end

local function org_drill_modify_of(of, q, fraction)
	--print("org_drill_modify_of<<<<<<<<")
	--print(vim.inspect(of))
	--print(vim.inspect(q))
	--print(vim.inspect(fraction))
	local temp = of * (0.72 + q * 0.07)
	return (1 - fraction) * of + fraction * temp
end

local function sm5(last_interval, n, ef, quality, failures, meanq, total_repeats, of_matrix, delta_days)
	--print("sm5<<<<<<<<")
	--print(vim.inspect(last_interval))
	--print(vim.inspect(n))
	--print(vim.inspect(ef))
	--print(vim.inspect(quality))
	--print(vim.inspect(failures))
	--print(vim.inspect(meanq))
	--print(vim.inspect(total_repeats))
	----print(vim.inspect(of_matrix))
	--print(vim.inspect(delta_days))
	--print("sm5>>>>>>>>>>>")
	if n == 0 then
		n = 1
	end
	assert(n > 0)
	assert(quality >= 0 and quality <= 5)
	if ef == 0 then
		ef = 2.5
	end
	if meanq == nil then
		meanq = quality
	else
		meanq = (quality + 1.0 * meanq * total_repeats) / (1 + total_repeats)
	end
	local next_ef = org_drill_modify_e_factor(ef, quality)
	local old_ef = ef
	local new_of =
		org_drill_modify_of(org_drill_get_optimal_factor_sm5(n, ef, of_matrix), quality, org_drill_learn_fraction)
	if org_drill_adjust_intervals_for_early_and_late_repetitions_p and delta_days and delta_days < 0 then
		new_of = org_drill_early_interval_factor(
			org_drill_get_optimal_factor_sm5(n, ef, of_matrix),
			org_drill_inter_repetition_interval_sm5(last_interval, n, ef, of_matrix),
			delta_days
		)
	end
	of_matrix = org_drill_set_optimal_factor(n, next_ef, of_matrix, org_drill_round_float(new_of, 3))
	ef = next_ef
	if quality <= org_drill_failure_quality then
		return {
			next_interval = -1,
			n = 1,
			ef = old_ef,
			failures = 1 + failures,
			meanq = meanq,
			total_repeats = 1 + total_repeats,
			of_matrix = of_matrix,
		}
	else
		--print("<<<<<")
		local next_interval = org_drill_inter_repetition_interval_sm5(last_interval, n, ef, of_matrix)
		--print(next_interval)
		if org_drill_add_random_noise_to_intervals_p == true then
			next_interval = next_interval * org_drill_random_dispersal_factor()
		end
		--print(next_interval)
		--print(">>>>")
		return {
			next_interval = next_interval,
			n = 1 + n,
			ef = ef,
			failures = failures,
			meanq = meanq,
			total_repeats = 1 + total_repeats,
			of_matrix = of_matrix,
		}
	end
end

local function sm2(last_interval, n, ef, quality, failures, meanq, total_repeats)
	if n == 0 then
		n = 1
	end
	assert(n > 0)
	assert(quality >= 0 and quality <= 5)
	if ef == 0 then
		ef = 2.5
	end

	if meanq == nil then
		meanq = quality
	else
		meanq = (quality + 1.0 * meanq * total_repeats) / (1 + total_repeats)
	end
	if quality <= org_drill_failure_quality then
		-- When an item is failed, its interval is reset to 0,
		-- but its EF is unchanged
		return {
			next_interval = -1,
			n = 1,
			ef = ef,
			failures = 1 + failures,
			meanq = meanq,
			total_repeats = 1 + total_repeats,
		}
	else
		local next_ef = org_drill_modify_e_factor(ef, quality)
		local interval = nil
		if n <= 1 then
			interval = 1
		elseif n == 2 then
			if org_drill_add_random_noise_to_intervals_p == true then
				if quality == 5 then
					interval = 6
				elseif quality == 4 then
					interval = 4
				elseif quality == 3 then
					interval = 3
				elseif quality == 2 then
					interval = 1
				else
					interval = -1
				end
			else
				interval = 6
			end
		else
			interval = last_interval * next_ef
		end
		local next_interval = interval
		if org_drill_add_random_noise_to_intervals_p == true then
			next_interval = last_interval + ((interval - last_interval) * org_drill_random_dispersal_factor())
		end
		return {
			next_interval = next_interval,
			n = 1 + n,
			ef = next_ef,
			failures = failures,
			meanq = meanq,
			total_repeats = 1 + total_repeats,
		}
	end
end

local function org_drill_entry_lapsed_p(input)
	return input.last_interval > 90

	--	local now_time = tonumber(os.time())
	--	local drill_interval = (now_time - input.drill_lasttime) / 60 / 60 / 24
	--	local lapsed_days = 90
	--	return (drill_interval or 0) > lapsed_days
end

local function wrap(quality, input, of_matrix)
	local now_time = tonumber(os.time())
	--local drill_interval = (now_time - input.drill_lasttime) / 60 / 60 / 24
	local delta_days = (input.drill_schedule - now_time) / 60 / 60 / 24
	return sm5(
		input.last_interval,
		input.drill_n,
		input.drill_ef,
		quality,
		input.drill_failures,
		input.drill_meanq,
		input.drill_total_repeats,
		of_matrix,
		delta_days
	)
end

local function org_drill_hypothetical_next_review_date(quality, input, of_matrix)
	local output = wrap(quality, input, of_matrix)
	if output.next_interval <= 0 then
		return 0
	elseif type(input.weight) == "number" and input.weight > 0 then
		return input.last_interval + math.max(1.0, (output.next_interval - input.last_interval) / input.weight)
	else
		return output.next_interval
	end
end

local function org_drill_hypothetical_next_review_dates(input, of_matrix)
	local intervals = {}
	for q = 0, 5 do
		table.insert(
			intervals,
			math.max(intervals[1] or 0, org_drill_hypothetical_next_review_date(q, input, of_matrix))
		)
	end
	return intervals
end

local function org_drill_smart_reschedule(quality, days_ahead, input, of_matrix)
	--print(days_ahead)
	local weight = input.weight or 1
	local output = wrap(quality, input, of_matrix)
	local next_interval = output.next_interval
	local last_interval = input.last_interval

	--print("<===")
	--print(vim.inspect(input.last_interval))
	--print(">===")

	if type(days_ahead) == "number" then
		next_interval = days_ahead
	end

	if days_ahead == nil and type(weight) == "number" and weight > 0 and next_interval >= 0 then
		next_interval = math.max(1.0, last_interval + (next_interval - last_interval) / weight)
	end

	local schedule_time = nil

	--if days_ahead == 0 then
	--	schedule_time = os.time() + 4 * 24 * 60 * 60
	if days_ahead <= 0 then
		schedule_time = os.time() + math.random(10) * 60
	else
		schedule_time = math.max(os.time(), tonumber(input.drill_schedule)) + next_interval * 24 * 60 * 60
	end

	schedule_time = math.min(os.time() + 90 * 24 * 60 * 60, schedule_time)
	--print(next_interval)

	output.schedule_time = schedule_time
	return output
end

local function start(input, quality, of_matrix)
	local next_review_dates = org_drill_hypothetical_next_review_dates(input, of_matrix)
	print("next_review_dates<<<<<<<<")
	print(vim.inspect(next_review_dates))
	quality = org_drill_entry_lapsed_p(input) and 2 or quality
	print(vim.inspect(quality))
	print("next_review_dates>>>>>>>")
	return org_drill_smart_reschedule(quality, next_review_dates[quality + 1], input, of_matrix)
end

return {
	start = start,
}
