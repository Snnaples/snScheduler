# snScheduler
Callback scheduler


USAGE:

<sup>
	
scheduleUserCallback(user_id, { 
    days = 5, hour = 14, minute = 30,
	date = os.date'*t',
	fnString = [[
		return function(user_id)
			vRP.giveMoney(user_id, 100)
		end
	]],
	varargs = {user_id or 1}
 })

scheduleServerCallback{
	label = 'Callback Name',
	
	days = 0,
	hour = 14,
	minute = 30,
	date = os.date'*t',
	fnString = [[
		return function(x,y,z)
			print(x,y,z)
			print"Hello, World!"
		end
	]],

	varargs = {1,5,2} -- arguments passed -> fnString

}
</sup>
