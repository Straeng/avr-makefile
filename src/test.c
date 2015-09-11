
#include <avr/io.h>
#include <util/delay.h>

int main(void)
{
	DDRB |= _BV(PB0);

	while(1)
	{
		_delay_ms(DELAY);
		PORTB ^= _BV(PB0);
	}
}
