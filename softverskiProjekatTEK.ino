/*
 * Biblioteka za lcd displej
 * Displej koji smo koristili je 16 x 2 sto znaci da 
 * ima dve vrste i 16 kolona
*/
#include <LiquidCrystal.h>
/*
 * rs - register select pin koji kontrolise gde u LCD memoriji pisemo
 * en - enable pin koji omogucuje upis u registre
 * d4, d5, d6, d7 - data pins su bitovi koje upisujemo u registre ili
 * citamo iz njih
*/
// inicijalizuje lcd displej, ako lcd ne ispisuje nista proverite
// da li su brojevi pinova dobri, ne moraju biti isti brojevi kao ovde
const int rs = 8, en = 9, d4 = 4, d5 = 5, d6 = 6, d7 = 7;
LiquidCrystal lcd(rs, en, d4, d5, d6, d7);
int numOfColumns = 16, numOfRows = 2;
float vin; //mereni napon
int deltaVin = 18; //razlika maksimalnog i minimalnog ulaznog napona
int maxAnalogValue = 1023; //maksimalni broj koraka
int reducedMaxAnalogValue; //redukovani broj koraka
int vinmin = -9; //minimalna vrednost ulaznog napona
int vout = 0; //izlazni napon
float arduinoMaxVoltage = 5; //maksimalna vrednost napona
float reducedMaxVoltage = 3.641; //redukovana vrednost napona


// funkcija koja se izvrsi samo jednom na pocetku i sluzi za pocetna podesavanja
void setup()
{
  lcd.begin(numOfColumns, numOfRows); // podesava broj kolona i vrsta
  // 9600 je maksimalan broj bitova koji se moze preneti
  Serial.begin(9600); // sluzi za pokretanje serial monitora
  lcd.setCursor(3,0); // pomera kursor na 0 vrstu i trecu kolonu
  lcd.print("VOLTMETAR"); // ispisuje na lcd
  // 5 : 1023 = 3,641 : x => x = 1023 * 3,641 / 5 => x = 745
  reducedMaxAnalogValue = round((maxAnalogValue * reducedMaxVoltage) / arduinoMaxVoltage);
}

// funkcija koju arduino izvrsava u petlji sve dok se ne iskljuci ploca
void loop()
{
  lcd.setCursor(5, 1);
  // cita sa A9 analognog pina i smesta u celobrojnu promenljivu vout
  vout = analogRead(A9); //izlazni napon
  Serial.print(vout);  // ispisuje na serijski monitor
  Serial.print(",");
  vin = (vout * deltaVin) / (float)reducedMaxAnalogValue + vinmin; //mereni napon
  //Serial.print("\nU = "); // '\n' oznacava prelazak u nov red
  Serial.println(vin);
  // ispisuje vrednost promenjive vin
  lcd.print(vin);
  delay(200);  // sacekaj 200 milisekundi
}
