module polar;

import saillog;

import std.string;
import std.file;
import std.algorithm;

import vibe.data.json;



struct Polar {

    this(float[float] curve){
        m_curve = curve;
    }
    
    this(string filename){
        this(getDataFromFile(filename));
    }
    
    float[float] getDataFromFile(string filename){
        float curve[float];
        try{
            string jsonText = readText(filename);
            Json json = parseJsonString(jsonText);
            foreach(Json el ; json){
                curve[to!float(el.key)] = to!float(el.value);
            }
        }
        catch(Exception e){
            SailLog.Warning("Error while parsing polar curve file : " , e);
        }
        
        return curve;
    }
    
    float getValue(float key){
        float value = m_curve.get(key, -1.0);
        //If value isn't in the table, we extrapolate it
        if(value == -1.0){
            value = extrapolate(key);
        }
        return value;
    }
    
    float extrapolate(float key){
        
        float key_prev = minPos(m_curve.keys)[0];
        float val_prev = m_curve[key_prev];
        
        float key_next = minPos!("a > b")(m_curve.keys)[0];
        float val_next = m_curve[key_next];
        
        foreach(index, value ; m_curve){
            
            //find previous key
            if(index<key && index>key_prev){
                key_prev = index;
                val_prev = value;
            }
            //find next key
            else if(index>key && index<key_next){
                key_next = index;
                val_next = value;
            }
        }
        
        //extrapolate value
        float value, coef_val, coef_key;
        
        coef_val = val_next - val_prev;
        coef_key = key_next - key_prev;
        
        float scale = (key - key_prev) / coef_key;
        
        value =  (coef_val * scale) + val_prev;
        
        //return value
        return value;
    }
    
private : 
    float m_curve[float];
    
    
    
    
    unittest {
        import std.math;
    
        float[float] values = [0.0:0.0, 90.0:0.5, 180.0:1.0];    
        Polar p = Polar(values);
        
        //Given values
        assert(p.getValue(0.0) == 0.0);
        assert(p.getValue(90.0) == 0.5);
        assert(p.getValue(180.0) == 1.0);
        
        //Extrapolated values
        assert(abs(p.getValue(22.5) - 0.125) <0.001);
        assert(abs(p.getValue(45.0) - 0.25) <0.001);
        assert(abs(p.getValue(135.0) - 0.75) <0.001);
        
        SailLog.Notify("Polar unittest done");
    }

}