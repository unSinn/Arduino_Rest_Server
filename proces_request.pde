

void parse_request (String request) {
    Serial.print("[parse_request] request: ");
    Serial.println(request);

    for (int i = 0; i < 4; i ++) { services_act_requested [i] = false; }
    for (int i = 0; i < 6; i ++) { services_sense_requested [i] = false; }

    if (request.startsWith("GET")) {
        Serial.println("[parse_request] request type: GET");
        String format = request.substring(request.indexOf(" ",4));
        request = request.substring(4, request.indexOf(' ',4));

        if (request.startsWith("/ ")) {
        } else {
            Serial.println("[parse_request] matched resource request: ");
            for(int i = 0; i < 6; i++) {
                if (request.startsWith("/" + services_sense_names[i])) {
                    Serial.print("[parse_request] matched sense resource request: ");
                    Serial.println(services_sense_names[i]);
                    
                }
            }
            read_next_service(request);
        }
    } 
}

void read_next_service(String request) {
//    Serial.print("[read_next_service] receiving new request: ");
//    Serial.println(request);

   for(int i = 0; i < 4; i++) {
        if (request.startsWith("/")) {
            request = request.substring(request.indexOf("/")+1);            
        }
       if (request.startsWith(services_act_names[i])) {
            services_act_requested[i] = true;

//            Serial.print("[read_next_service] reading matched request: ");
//            Serial.println(request);

            int end_index = request.indexOf("/");
            if (end_index == -1) return;
            request = request.substring(end_index+1);

//            Serial.print("[read_next_service] current service name removed: ");
//            Serial.println(request);


            if (request.length() < 2) return;

            int request_end_index = request.indexOf("/");
            if (request_end_index == -1) { 
                int service_value = convert_string2int(request.substring(0));
                if (service_value != -1) services_act_values[i] = service_value;
                else read_next_service(request);
//                Serial.print("[read_next_service] last element request: ");
//                Serial.println(request);

            } else { 
                // try to convert the current element of the url into a number
                // if the conversion fails (-1) then read the method
                int service_value = convert_string2int(request.substring(0,request_end_index));
                if (service_value != -1) {
                    services_act_values[i] = convert_string2int(request.substring(0,request_end_index)); 
                    request = request.substring(request_end_index+1);
//                    Serial.print("[read_next_service] number read, reduced request: ");
//                    Serial.println(request);
                    read_next_service(request);
                    break;
                } else {
//                    Serial.print("[read_next_service] not a number, full request: ");
//                    Serial.println(request);
                    read_next_service(request);
                    break;
                }
           } 
       }
    }
}

int convert_string2int(String number) {
  int return_num = 0;
  
  int reverse_counter = number.length()-1;
  for(int i = 0; i < number.length(); i++) {
      char cur_char = number.charAt(i);
      if (cur_char < 48 || cur_char > 57) return -1;
      int mult = 1;
      for(int j = 0; j < reverse_counter; j++) {
        mult = mult * 10;
      }
      if (mult == 0) mult = 1;
      return_num += (int(cur_char)-48) * mult; 
      reverse_counter--;
  }
//  Serial.print("[convert_string2int] orig number: ");
//  Serial.print(number);
//  Serial.print(" int number: ");
//  Serial.println(return_num);
  return return_num;
}

void run() {
  
  if (millis() - last_reading > reading_interval) {
      Serial.println("[run] reading data from sensors and writing to actuators");
      last_reading = millis();
      read_data();
      write_data();
  }
}

void write_data() {
    for(int i = 0; i < 4; i++) {
        if (services_act_pins[i] == 3 || services_act_pins[i] == 5 || 
            services_act_pins[i] == 6 || services_act_pins[i] == 9) { 
            analogWrite(services_act_pins[i], services_act_values[i]);
        } else {
            digitalWrite(services_act_pins[i], constrain(services_act_values[i], 0, 1));
        }
//        Serial.print("[write_data] state of actuators ");
//        Serial.print(services_act_names[i]);
//        Serial.print(": ");
//        Serial.println(services_act_values[i]);
    }  
}

void read_data() {
    for(int i = 0; i < 6; i++) {
      if (services_sense_pins[i] >= A0) { 
          services_sense_values[i] = analogRead(services_sense_pins[i]); 
      } else { 
          services_sense_values[i] = digitalRead(services_sense_pins[i]); 
      }
//      Serial.print("[read_data] state of sensors ");
//      Serial.print(services_sense_names[i]);
//      Serial.print(": ");
//      Serial.println(services_sense_values[i]);
    } 
}

void send_response(Client client) {
    client.println("HTTP/1.1 200 OK");
    client.println("Content-Type: text/html");
    client.println();

    read_data();
    client.println("Sensor Resource States: <br />");
    // output the value of each analog input pin
    for(int i = 0; i < 6; i++) {
        client.print(services_sense_names[i]);
        client.print(" = ");
        client.print(services_sense_values[i]);
        client.println("<br />");
    }
    client.println("<br />");

    write_data();
    client.println("Actuator Resource States: <br />");
    // output the value of each analog input pin
    for(int i = 0; i < 4; i++) {
        if (services_act_requested[i]) {
            client.print(services_act_names[i]);
            client.print(" = ");
            client.print(services_act_values[i]);
            client.println("<br />");
        }
    }

}

