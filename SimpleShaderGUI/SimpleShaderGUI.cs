using System.Collections;
using System.Collections.Generic;
using System;
using UnityEditor;
using UnityEngine;
using UnityEngine.Events;

namespace TA
{
    public class GUIData
    {
        public static Dictionary<string, bool> group = new Dictionary<string, bool>();
        public static Dictionary<string, bool> keyWord = new Dictionary<string, bool>();
    }
    public class SimpleShaderGUI : ShaderGUI
    {
        public MaterialProperty[] props;
        public MaterialEditor materialEditor;
        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
        {
            this.props = props;
            this.materialEditor = materialEditor;

            base.OnGUI(materialEditor, props);
        }
        public static MaterialProperty FindProp(string propertyName, MaterialProperty[] properties, bool propertyIsMandatory = false)
        {
            return FindProperty(propertyName, properties, propertyIsMandatory);
        }
    }
    public class Func
    {
        public static void TurnColorDraw(Color useColor, UnityAction action)
        {
            var c = GUI.color;
            GUI.color = useColor;
            if (action != null)
                action();
            GUI.color = c;
        }

        public static string GetKeyWord(string keyWord, string propName)
        {
            string k;
            if (keyWord == "" || keyWord == "__")
            {
                k = propName.ToUpperInvariant() + "_ON";
            }
            else
            {
                k = keyWord.ToUpperInvariant();
            }
            return k;
        }

        public static bool Foldout(ref bool display, bool value, bool hasToggle, string title)
        {
            var style = new GUIStyle("ShurikenModuleTitle");// BG
            style.font = EditorStyles.boldLabel.font;
            style.fontSize = EditorStyles.boldLabel.fontSize + 3;
            style.border = new RectOffset(15, 7, 4, 4);
            style.fixedHeight = 30;
            style.contentOffset = new Vector2(50f, 0f);
            
            var rect = GUILayoutUtility.GetRect(16f, 25f, style);// Box
            rect.yMin -= 10;
            rect.yMax += 10;
            GUI.Box(rect, "", style);

            GUIStyle titleStyle = new GUIStyle(EditorStyles.boldLabel);// Font
            titleStyle.fontSize += 2;

            EditorGUI.PrefixLabel(
                new Rect(
                    hasToggle ? rect.x + 50f : rect.x + 25f,
                    rect.y + 6f, 13f, 13f),// title pos
                new GUIContent(title),
                titleStyle);

            var triangleRect = new Rect(rect.x + 4f, rect.y + 8f, 13f, 13f);// triangle

            var clickRect = new Rect(rect);// click
            clickRect.height -= 15f;

            var toggleRect = new Rect(triangleRect.x + 20f, triangleRect.y + 0f, 13f, 13f);

            var e = Event.current;
            if (e.type == EventType.Repaint)
            {
                EditorStyles.foldout.Draw(triangleRect, false, false, display, false);
                if (hasToggle)
                {
                    if (EditorGUI.showMixedValue)
                        GUI.Toggle(toggleRect, false, "", new GUIStyle("ToggleMixed"));
                    else
                        GUI.Toggle(toggleRect, value, "");
                }
            }

            if (hasToggle && e.type == EventType.MouseDown && toggleRect.Contains(e.mousePosition))
            {
                value = !value;
                e.Use();
            }
            else if (e.type == EventType.MouseDown && clickRect.Contains(e.mousePosition))
            {
                display = !display;
                e.Use();
            }
            return value;
        }

        public static void PowerSlider(MaterialProperty prop, float power, Rect position, GUIContent label)
        {
            int controlId = GUIUtility.GetControlID("EditorSliderKnob".GetHashCode(), FocusType.Passive, position);
            float left = prop.rangeLimits.x;
            float right = prop.rangeLimits.y;
            float start = left;
            float end = right;
            float value = prop.floatValue;
            float originValue = prop.floatValue;

            if ((double)power != 1.0)
            {
                start = Func.PowPreserveSign(start, 1f / power);
                end = Func.PowPreserveSign(end, 1f / power);
                value = Func.PowPreserveSign(value, 1f / power);
            }

            EditorGUI.BeginChangeCheck();

            var labelWidth = EditorGUIUtility.labelWidth;
            EditorGUIUtility.labelWidth = 0;

            Rect position2 = EditorGUI.PrefixLabel(position, label);
            position2 = new Rect(position2.x, position2.y, position2.width - EditorGUIUtility.fieldWidth - 5, position2.height);

            if (position2.width >= 50f)
                value = GUI.Slider(position2, value, 0.0f, start, end, GUI.skin.horizontalSlider, !EditorGUI.showMixedValue ? GUI.skin.horizontalSliderThumb : (GUIStyle)"SliderMixed", true, controlId);

            if ((double)power != 1.0)
                value = Func.PowPreserveSign(value, power);

            position.xMin += position.width - SubDrawer.propRight;
            value = EditorGUI.FloatField(position, value);

            EditorGUIUtility.labelWidth = labelWidth;
            if (value != originValue)
                prop.floatValue = Mathf.Clamp(value, Mathf.Min(left, right), Mathf.Max(left, right));
        }
        public static MaterialProperty[] GetProperties(MaterialEditor editor)
        {
            if (editor.customShaderGUI != null && editor.customShaderGUI is SimpleShaderGUI)
            {
                SimpleShaderGUI gui = editor.customShaderGUI as SimpleShaderGUI;
                return gui.props;
            }
            else
            {
                Debug.LogWarning("TA.SimpleShaderGUI to the end of your shader!");
                return null;
            }
        }

        public static float PowPreserveSign(float f, float p)
        {
            float num = Mathf.Pow(Mathf.Abs(f), p);
            if ((double)f < 0.0)
                return -num;
            return num;
        }

        public static Color RGBToHSV(Color color)
        {
            float h, s, v;
            Color.RGBToHSV(color, out h, out s, out v);
            return new Color(h, s, v, color.a);
        }
        public static Color HSVToRGB(Color color)
        {
            var c = Color.HSVToRGB(color.r, color.g, color.b);
            c.a = color.a;
            return c;
        }

        public static void SetShaderKeyWord(UnityEngine.Object[] materials, string keyWord, bool isEnable)
        {
            foreach (Material m in materials)
            {
                if (m.IsKeywordEnabled(keyWord))
                {
                    if (!isEnable) m.DisableKeyword(keyWord);
                }
                else
                {
                    if (isEnable) m.EnableKeyword(keyWord);
                }
            }
        }

        public static void SetShaderKeyWord(UnityEngine.Object[] materials, string[] keyWords, int index)
        {
            Debug.Assert(keyWords.Length >= 1 && index < keyWords.Length && index >= 0, $"KeyWords:{keyWords} or Index:{index} Error! ");
            for (int i = 0; i < keyWords.Length; i++)
            {
                SetShaderKeyWord(materials, keyWords[i], index == i);
                if (GUIData.keyWord.ContainsKey(keyWords[i]))
                {
                    GUIData.keyWord[keyWords[i]] = index == i;
                }
                else
                {
                    Debug.LogError("KeyWord not exist! Throw a shader error to refresh the instance.");
                }
            }
        }

        public static bool NeedShow(string group)
        {
            if (group == "" || group == "_")
                return true;
            if (GUIData.group.ContainsKey(group))
            {// 一般sub
                return GUIData.group[group];
            }
            // else
            // {// 存在后缀，可能是依据枚举的条件sub
            //     foreach (var prefix in GUIData.group.Keys)
            //     {
            //         if (group.Contains(prefix))
            //         {
            //             //拿到后缀
            //             string suffix = group.Substring(prefix.Length, group.Length - prefix.Length).ToUpperInvariant();
            //             if (GUIData.keyWord.ContainsKey(suffix))
            //             {
            //                 return GUIData.keyWord[suffix] && GUIData.group[prefix];
            //             }
            //         }
            //     }
            //     return false;
            // }
            return false;
        }
        public static bool NeedShow(string group,string key)
        {
            key = key.ToUpperInvariant();
            return GUIData.group.ContainsKey(group) && GUIData.keyWord.ContainsKey(key)&&
                   GUIData.keyWord[key] && GUIData.group[group];
        }
    }
    
    /// <summary>
    /// 创建一个折叠组
    /// group：折叠组，不提供则使用属性名称（非显示名称）
    /// keyword：_为忽略，不填和__为属性名大写 + _ON
    /// style：0 默认关闭；1 默认打开；2 默认关闭无toggle；3 默认打开无toggle
    /// </summary>
    public class MainDrawer : MaterialPropertyDrawer
    {
        bool show = false;
        float height;
        string group;
        string keyWord;
        int style;
        public MainDrawer() : this("") { }
        public MainDrawer(string group) : this(group, "", 3) { }
        public MainDrawer(string group, string keyword) : this(group, keyword, 0) { }
        public MainDrawer(string group, string keyWord, float style)
        {
            this.group = group;
            this.keyWord = keyWord;
            this.style = (int)style;
        }

        public override void OnGUI(Rect position, MaterialProperty prop, GUIContent label, MaterialEditor editor)
        {
            // GUI.backgroundColor = Color.yellow;
            // GUI.color = Color.yellow;
            // GUI.contentColor = Color.yellow;
            
            var value = prop.floatValue == 1.0f;
            EditorGUI.showMixedValue = prop.hasMixedValue;
            string g = group != "" ? group : prop.name;
            var lastShow = GUIData.group.ContainsKey(g) ? GUIData.group[g] : true;
            show = ((style == 1 || style == 3) && lastShow) ? true : show;

            bool result = Func.Foldout(ref show, value, style == 0 || style == 1, label.text);
            EditorGUI.showMixedValue = false;

            if (result != value)
            {
                prop.floatValue = result ? 1.0f : 0.0f;
                Func.SetShaderKeyWord(editor.targets, Func.GetKeyWord(keyWord, prop.name), result);
            }
            else
            {
                if (!prop.hasMixedValue)
                    Func.SetShaderKeyWord(editor.targets, Func.GetKeyWord(keyWord, prop.name), result);
            }

            if (GUIData.group.ContainsKey(g))
            {
                GUIData.group[g] = show;
            }
            else
            {
                GUIData.group.Add(g, show);
            }
        }
    }
    
    /// <summary>
    /// 在折叠组内以默认形式绘制属性
    /// group：父折叠组的group key，
    /// </summary>
    public class SubDrawer : MaterialPropertyDrawer
    {
        public static readonly int propRight = 80;
        public static readonly int propHeight = 20;
        protected string group = "";
        protected float height;
        protected bool needShow => Func.NeedShow(group);
        protected virtual bool matchPropType => true;
        protected MaterialProperty prop;
        protected MaterialProperty[] props;

        public SubDrawer() { }
        public SubDrawer(string group)
        {
            this.group = group;
        }

        public override void OnGUI(Rect position, MaterialProperty prop, GUIContent label, MaterialEditor editor)
        {
            height = position.height;
            this.prop = prop;
            props = Func.GetProperties(editor);
            if (group != "" && group != "_")
            {
                EditorGUI.indentLevel++;
                if (needShow)
                {
                    if (matchPropType)
                        DrawProp(position, prop, label, editor);
                    else
                    {
                        Debug.LogWarning($"{this.GetType()} does not support this MaterialProperty type:'{prop.type}'!");
                        editor.DefaultShaderProperty(prop, label.text);
                    }
                }
                EditorGUI.indentLevel--;
            }
            else
            {
                if (matchPropType)
                    DrawProp(position, prop, label, editor);
                else
                {
                    Debug.LogWarning($"{this.GetType()} does not support this MaterialProperty type:'{prop.type}'!");
                    editor.DefaultShaderProperty(prop, label.text);
                }
            }
        }
        public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor)
        {
            return needShow ? height : -2;
        }
        // 绘制自定义样式属性
        public virtual void DrawProp(Rect position, MaterialProperty prop, GUIContent label, MaterialEditor editor)
        {
            editor.DefaultShaderProperty(prop, label.text);
        }
    }
    
     /// <summary>
    /// 在折叠组内以默认形式绘制属性
    /// group：父折叠组的group key，
    /// </summary>
    public class SubKeyItemDrawer : MaterialPropertyDrawer
    {
        public static readonly int propRight = 80;
        public static readonly int propHeight = 20;
        protected string group = "";
        protected string key = "";
        protected float height;
        // protected bool needShow => Func.NeedShow(group+key);
        protected bool needShow => Func.NeedShow(group,key);
        protected virtual bool matchPropType => true;
        protected MaterialProperty prop;
        protected MaterialProperty[] props;
        
        public SubKeyItemDrawer(string group,string key)
        {
            this.group = group;
            this.key = key;
        }

        public override void OnGUI(Rect position, MaterialProperty prop, GUIContent label, MaterialEditor editor)
        {
            height = position.height;
            this.prop = prop;
            props = Func.GetProperties(editor);
            if (group != "" && group != "_")
            {
                EditorGUI.indentLevel++;
                if (needShow)
                {
                    if (matchPropType)
                        DrawProp(position, prop, label, editor);
                    else
                    {
                        Debug.LogWarning($"{this.GetType()} does not support this MaterialProperty type:'{prop.type}'!");
                        editor.DefaultShaderProperty(prop, label.text);
                    }
                }
                EditorGUI.indentLevel--;
            }
            else
            {
                if (matchPropType)
                    DrawProp(position, prop, label, editor);
                else
                {
                    Debug.LogWarning($"{this.GetType()} does not support this MaterialProperty type:'{prop.type}'!");
                    editor.DefaultShaderProperty(prop, label.text);
                }
            }
        }
        public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor)
        {
            return needShow ? height : -2;
        }
        // 绘制自定义样式属性
        public virtual void DrawProp(Rect position, MaterialProperty prop, GUIContent label, MaterialEditor editor)
        {
            editor.DefaultShaderProperty(prop, label.text);
        }
    }
     
     /// <summary>
    /// 在折叠组内以默认形式绘制属性
    /// group：父折叠组的group "_" 为没有组
    /// </summary>
    public class ButtomItemDrawer : MaterialPropertyDrawer
    {
        public static readonly int propRight = 80;
        public static readonly int propHeight = 20;
        protected string group = "";
        protected string key = "";
        protected float height;
        // protected bool needShow => Func.NeedShow(group+key);
        protected bool needShow
        {
            get
            {
                if (group == "" || group == "_")
                    return GUIData.keyWord.ContainsKey(key) && GUIData.keyWord[key];
                else
                {
                    return Func.NeedShow(group, key);
                }
            }
        }

        protected virtual bool matchPropType => true;
        protected MaterialProperty prop;
        protected MaterialProperty[] props;
        
        public ButtomItemDrawer(string group,string key)
        {
            this.group = group;
            this.key = key.ToUpperInvariant();
        }

        public override void OnGUI(Rect position, MaterialProperty prop, GUIContent label, MaterialEditor editor)
        {
            height = position.height;
            this.prop = prop;
            props = Func.GetProperties(editor);
            // if (group != "" && group != "_")
            {
                EditorGUI.indentLevel++;
                if (needShow)
                {
                    if (matchPropType)
                        DrawProp(position, prop, label, editor);
                    else
                    {
                        Debug.LogWarning($"{this.GetType()} does not support this MaterialProperty type:'{prop.type}'!");
                        editor.DefaultShaderProperty(prop, label.text);
                    }
                }
                EditorGUI.indentLevel--;
            }
            // else
            // {
            //     if (matchPropType)
            //         DrawProp(position, prop, label, editor);
            //     else
            //     {
            //         Debug.LogWarning($"{this.GetType()} does not support this MaterialProperty type:'{prop.type}'!");
            //         editor.DefaultShaderProperty(prop, label.text);
            //     }
            // }
            
        }
        public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor)
        {
            return needShow ? height : -2;
        }
        // 绘制自定义样式属性
        public virtual void DrawProp(Rect position, MaterialProperty prop, GUIContent label, MaterialEditor editor)
        {
            editor.DefaultShaderProperty(prop, label.text);
        }
    }
     
    /// <summary>
    /// 在折叠组内以默认形式绘制属性
    /// group：父折叠组的group "_" 为没有组
    /// </summary>
    public class SubToggleItemDrawer : MaterialPropertyDrawer
    {
        public static readonly int propRight = 80;
        public static readonly int propHeight = 20;
        protected string group = "";
        protected string key = "";
        protected float height;
        // protected bool needShow => Func.NeedShow(group+key);
        protected bool needShow
        {
            get
            {
                if (group == "" || group == "_")
                    return GUIData.keyWord.ContainsKey(key) && GUIData.keyWord[key];
                else
                {
                    return Func.NeedShow(group, key);
                }
            }
        }

        protected virtual bool matchPropType => true;
        protected MaterialProperty prop;
        protected MaterialProperty[] props;
        
        public SubToggleItemDrawer(string group,string key)
        {
            this.group = group;
            this.key = key.ToUpperInvariant();
        }

        public override void OnGUI(Rect position, MaterialProperty prop, GUIContent label, MaterialEditor editor)
        {
            height = position.height;
            this.prop = prop;
            props = Func.GetProperties(editor);
            // if (group != "" && group != "_")
            {
                EditorGUI.indentLevel++;
                if (needShow)
                {
                    if (matchPropType)
                        DrawProp(position, prop, label, editor);
                    else
                    {
                        Debug.LogWarning($"{this.GetType()} does not support this MaterialProperty type:'{prop.type}'!");
                        editor.DefaultShaderProperty(prop, label.text);
                    }
                }
                EditorGUI.indentLevel--;
            }
            // else
            // {
            //     if (matchPropType)
            //         DrawProp(position, prop, label, editor);
            //     else
            //     {
            //         Debug.LogWarning($"{this.GetType()} does not support this MaterialProperty type:'{prop.type}'!");
            //         editor.DefaultShaderProperty(prop, label.text);
            //     }
            // }
            
        }
        public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor)
        {
            return needShow ? height : -2;
        }
        // 绘制自定义样式属性
        public virtual void DrawProp(Rect position, MaterialProperty prop, GUIContent label, MaterialEditor editor)
        {
            editor.DefaultShaderProperty(prop, label.text);
        }
    }
     
     
     /// <summary>
    /// k为对应KeyWord，float值为当前激活的数组index , group：父折叠组的group "_" 为没有组
    /// </summary>
    public class ButtonDrawer : SubDrawer
    {
        #region 
        public ButtonDrawer(string group, string k1) : this(group,  new string[1] { k1 }) { }
        public ButtonDrawer(string group, string k1,  string k2) : this(group,  new string[2] { k1, k2 }) { }
        public ButtonDrawer(string group,  string k1,  string k2,  string k3) : this(group,  new string[3] { k1, k2, k3 }) { }
        public ButtonDrawer(string group,  string k1,  string k2,  string k3, string k4) : this(group,  new string[4] { k1, k2, k3, k4 }) { }
        public ButtonDrawer(string group, string k1, string k2,  string k3,  string k4, string k5) : this(group,  new string[5] { k1, k2, k3, k4, k5 }) { }
        
        public ButtonDrawer(string group,  string[] keyWords)
        {
            this.group = group;
            this.names = keyWords;
            for (int i = 0; i < keyWords.Length; i++)
            {
                keyWords[i] = keyWords[i].ToUpperInvariant();
                if (!GUIData.keyWord.ContainsKey(keyWords[i]))
                {
                    GUIData.keyWord.Add(keyWords[i], false);
                }
            }
            this.keyWords = keyWords;
            this.values = new int[keyWords.Length];
            for (int index = 0; index < keyWords.Length; ++index)
                this.values[index] = index;
        }
        #endregion
        
        protected override bool matchPropType => prop.type == MaterialProperty.PropType.Float;
        string[] names, keyWords;
        int[] values;
        public override void DrawProp(Rect position, MaterialProperty prop, GUIContent label, MaterialEditor editor)
        {
            var style = new GUIStyle("ShurikenModuleTitle");// BG
            style.font = EditorStyles.boldLabel.font;
            style.fontSize = EditorStyles.boldLabel.fontSize + 3;
            style.border = new RectOffset(20, 7, 4, 4);
            style.fixedHeight = 30;
            style.contentOffset = new Vector2(50f, 0f);
            
            var rect = EditorGUILayout.GetControlRect();
            int index = (int)prop.floatValue;

            EditorGUI.BeginChangeCheck();
            EditorGUI.showMixedValue = prop.hasMixedValue;
             
            // int num = EditorGUI.IntPopup(rect, label.text, index, this.names, this.values);
            int num = index;
            GUILayout.BeginHorizontal();
            for (int i = 0; i < keyWords.Length; i++)
            {
                if (index == i)
                {
                    if (GUILayout.Button(keyWords[i],style))
                    {
                        index = i;
                    }
                }
                else
                {
                    if (GUILayout.Button(keyWords[i]))
                    {
                        index = i;
                    }
                }
            }
            GUILayout.EndHorizontal();
            
            EditorGUI.showMixedValue = false;
            if (EditorGUI.EndChangeCheck())
            {
                prop.floatValue = (float)index;
            }
            Func.SetShaderKeyWord(editor.targets, keyWords, index);
        }
    }
    
    /// <summary>
    /// k为对应KeyWord，float值为当前激活的数组index
    /// </summary>
    public class SubKeyDrawer : SubDrawer
    {
        #region 
        public SubKeyDrawer(string group, string k1) : this(group,  new string[1] { k1 }) { }
        public SubKeyDrawer(string group, string k1,  string k2) : this(group,  new string[2] { k1, k2 }) { }
        public SubKeyDrawer(string group,  string k1,  string k2,  string k3) : this(group,  new string[3] { k1, k2, k3 }) { }
        public SubKeyDrawer(string group,  string k1,  string k2,  string k3, string k4) : this(group,  new string[4] { k1, k2, k3, k4 }) { }
        public SubKeyDrawer(string group, string k1, string k2,  string k3,  string k4, string k5) : this(group,  new string[5] { k1, k2, k3, k4, k5 }) { }
        public SubKeyDrawer(string group,  string[] keyWords)
        {
            this.group = group;
            this.names = keyWords;
            for (int i = 0; i < keyWords.Length; i++)
            {
                keyWords[i] = keyWords[i].ToUpperInvariant();
                if (!GUIData.keyWord.ContainsKey(keyWords[i]))
                {
                    GUIData.keyWord.Add(keyWords[i], false);
                }
            }
            this.keyWords = keyWords;
            this.values = new int[keyWords.Length];
            for (int index = 0; index < keyWords.Length; ++index)
                this.values[index] = index;
        }
        #endregion
        
        protected override bool matchPropType => prop.type == MaterialProperty.PropType.Float;
        string[] names, keyWords;
        int[] values;
        public override void DrawProp(Rect position, MaterialProperty prop, GUIContent label, MaterialEditor editor)
        {
            var rect = EditorGUILayout.GetControlRect();
            int index = (int)prop.floatValue;

            EditorGUI.BeginChangeCheck();
            EditorGUI.showMixedValue = prop.hasMixedValue;
            int num = EditorGUI.IntPopup(rect, label.text, index, this.names, this.values);
            EditorGUI.showMixedValue = false;
            if (EditorGUI.EndChangeCheck())
            {
                prop.floatValue = (float)num;
            }
            Func.SetShaderKeyWord(editor.targets, keyWords, num);
        }
    }
    
    /// <summary>
    /// n为显示的name，k为对应KeyWord，float值为当前激活的数组index
    /// </summary>
    public class SubNameKeyDrawer : SubDrawer
    {
        #region 
        public SubNameKeyDrawer(string group, string n1, string k1) : this(group, new string[1] { n1 }, new string[1] { k1 }) { }
        public SubNameKeyDrawer(string group, string n1, string k1, string n2, string k2) : this(group, new string[2] { n1, n2 }, new string[2] { k1, k2 }) { }
        public SubNameKeyDrawer(string group, string n1, string k1, string n2, string k2, string n3, string k3) : this(group, new string[3] { n1, n2, n3 }, new string[3] { k1, k2, k3 }) { }
        public SubNameKeyDrawer(string group, string n1, string k1, string n2, string k2, string n3, string k3, string n4, string k4) : this(group, new string[4] { n1, n2, n3, n4 }, new string[4] { k1, k2, k3, k4 }) { }
        public SubNameKeyDrawer(string group, string n1, string k1, string n2, string k2, string n3, string k3, string n4, string k4, string n5, string k5) : this(group, new string[5] { n1, n2, n3, n4, n5 }, new string[5] { k1, k2, k3, k4, k5 }) { }
        public SubNameKeyDrawer(string group, string[] names, string[] keyWords)
        {
            this.group = group;
            this.names = names;
            for (int i = 0; i < keyWords.Length; i++)
            {
                keyWords[i] = keyWords[i].ToUpperInvariant();
                if (!GUIData.keyWord.ContainsKey(keyWords[i]))
                {
                    GUIData.keyWord.Add(keyWords[i], false);
                }
            }
            this.keyWords = keyWords;
            this.values = new int[keyWords.Length];
            for (int index = 0; index < keyWords.Length; ++index)
                this.values[index] = index;
        }
        #endregion
        
        protected override bool matchPropType => prop.type == MaterialProperty.PropType.Float;
        string[] names, keyWords;
        int[] values;
        public override void DrawProp(Rect position, MaterialProperty prop, GUIContent label, MaterialEditor editor)
        {
            var rect = EditorGUILayout.GetControlRect();
            int index = (int)prop.floatValue;

            EditorGUI.BeginChangeCheck();
            EditorGUI.showMixedValue = prop.hasMixedValue;
            int num = EditorGUI.IntPopup(rect, label.text, index, this.names, this.values);
            EditorGUI.showMixedValue = false;
            if (EditorGUI.EndChangeCheck())
            {
                prop.floatValue = (float)num;
            }
            Func.SetShaderKeyWord(editor.targets, keyWords, num);
        }
    }

    /// <summary>
    /// 以单行显示Texture，支持额外属性
    /// group为折叠组title，不填则不加入折叠组
    /// extraPropName为需要显示的额外属性名称
    /// </summary>
    public class TexDrawer : SubDrawer
    {
        public TexDrawer() : this("", "") { }
        public TexDrawer(string group) : this(group, "") { }
        public TexDrawer(string group, string extraPropName)
        {
            this.group = group;
            this.extraPropName = extraPropName;
        }
        protected override bool matchPropType => prop.type == MaterialProperty.PropType.Texture;
        string extraPropName;

        public override void DrawProp(Rect position, MaterialProperty prop, GUIContent label, MaterialEditor editor)
        {
            EditorGUI.ColorField(new Rect(-999, 0, 0, 0), new Color(0, 0, 0, 0));

            var r = EditorGUILayout.GetControlRect();
            MaterialProperty p = null;
            if (extraPropName != "" && extraPropName != "_")
                p = SimpleShaderGUI.FindProp(extraPropName, props, true);

            if (p != null)
            {
                Rect rect = Rect.zero;
                if (p.type == MaterialProperty.PropType.Range)
                {
                    var w = EditorGUIUtility.labelWidth;
                    EditorGUIUtility.labelWidth = 0;
                    rect = MaterialEditor.GetRectAfterLabelWidth(r);
                    EditorGUIUtility.labelWidth = w;
                }
                else
                    rect = MaterialEditor.GetRectAfterLabelWidth(r);

                editor.TexturePropertyMiniThumbnail(r, prop, label.text, label.tooltip);

                var i = EditorGUI.indentLevel;
                EditorGUI.indentLevel = 0;
                editor.ShaderProperty(rect, p, string.Empty);
                EditorGUI.indentLevel = i;
            }
            else
            {
                EditorGUI.showMixedValue = prop.hasMixedValue;
                editor.TexturePropertyMiniThumbnail(r, prop, label.text, label.tooltip);
            }
            EditorGUI.showMixedValue = false;
        }
    }
    /// <summary>
    /// 支持并排最多4个颜色，支持HSV
    /// !!!注意：更改参数需要手动刷新Drawer实例，在shader中随意输入字符引发报错再撤销以刷新Drawer实例
    /// </summary>
    public class ColorDrawer : SubDrawer
    {
        public ColorDrawer(string group, string parameter) : this(group, parameter, "", "", "") { }
        public ColorDrawer(string group, string parameter, string color2) : this(group, parameter, color2, "", "") { }
        public ColorDrawer(string group, string parameter, string color2, string color3) : this(group, parameter, color2, color3, "") { }
        public ColorDrawer(string group, string parameter, string color2, string color3, string color4)
        {
            this.group = group;
            this.parameter = parameter.ToUpperInvariant();
            this.colorStr[0] = color2;
            this.colorStr[1] = color3;
            this.colorStr[2] = color4;
        }
        const string preHSVKeyWord = "_HSV_OTColor";
        protected override bool matchPropType => prop.type == MaterialProperty.PropType.Color;
        bool isHSV => parameter.Contains("HSV");
        bool lastHSV;
        string parameter;
        string[] colorStr = new string[3];
        public override void DrawProp(Rect position, MaterialProperty prop, GUIContent label, MaterialEditor editor)
        {
            Stack<MaterialProperty> cProps = new Stack<MaterialProperty>();
            for (int i = 0; i < 4; i++)
            {
                if (i == 0)
                {
                    cProps.Push(prop);
                    continue;
                }
                var p = SimpleShaderGUI.FindProp(colorStr[i - 1], props);
                if (p != null && p.type == MaterialProperty.PropType.Color)
                    cProps.Push(p);
            }
            int count = cProps.Count;

            var rect = EditorGUILayout.GetControlRect();

            var p1 = cProps.Pop();
            EditorGUI.showMixedValue = p1.hasMixedValue;
            editor.ColorProperty(rect, p1, label.text);

            for (int i = 1; i < count; i++)
            {
                var cProp = cProps.Pop();
                EditorGUI.showMixedValue = cProp.hasMixedValue;
                Rect r = new Rect(rect);
                var interval = 13 * i * (-0.25f + EditorGUI.indentLevel * 1.25f);
                float w = propRight * (0.8f + EditorGUI.indentLevel * 0.2f);
                r.xMin += r.width - w * (i + 1) + interval;
                r.xMax -= w * i - interval;

                EditorGUI.BeginChangeCheck();
                Color src, dst;
                if (isHSV)
                    src = Func.HSVToRGB(cProp.colorValue.linear).gamma;
                else
                    src = cProp.colorValue;
                var hdr = (prop.flags & MaterialProperty.PropFlags.HDR) != MaterialProperty.PropFlags.None;
                dst = EditorGUI.ColorField(r, GUIContent.none, src, true, true, hdr);
                if (EditorGUI.EndChangeCheck())
                {
                    if (isHSV)
                        cProp.colorValue = Func.RGBToHSV(dst.linear).gamma;
                    else
                        cProp.colorValue = dst;
                }
            }
            EditorGUI.showMixedValue = false;
            Func.SetShaderKeyWord(editor.targets, preHSVKeyWord, isHSV);
        }
    }

    /// <summary>
    /// 以SubToggle形式显示float，KeyWord行为与内置Toggle一致，
    /// keyword：_为忽略，不填和__为属性名大写 + _ON，将KeyWord后缀于group可根据toggle是否显示
    /// </summary>
    public class SubToggleDrawer : SubDrawer
    {
        public SubToggleDrawer(string group) : this(group, "") { }
        public SubToggleDrawer(string group, string keyWord)
        {
            this.group = group;
            this.keyWord = keyWord;
        }
        protected override bool matchPropType => prop.type == MaterialProperty.PropType.Float;
        string keyWord;
        public override void DrawProp(Rect position, MaterialProperty prop, GUIContent label, MaterialEditor editor)
        {
            EditorGUI.showMixedValue = prop.hasMixedValue;
            EditorGUI.BeginChangeCheck();
            var value = EditorGUILayout.Toggle(label, prop.floatValue > 0.0f);
            string k = Func.GetKeyWord(keyWord, prop.name);
            if (EditorGUI.EndChangeCheck())
            {
                prop.floatValue = value ? 1.0f : 0.0f;
                Func.SetShaderKeyWord(editor.targets, k, value);
            }
            else
            {
                if (!prop.hasMixedValue)
                    Func.SetShaderKeyWord(editor.targets, k, value);
            }
            if (GUIData.keyWord.ContainsKey(k))
            {
                GUIData.keyWord[k] = value;
            }
            else
            {
                GUIData.keyWord.Add(k, value);
            }
            EditorGUI.showMixedValue = false;
        }
    }

    /// <summary>
    /// 同内置PowerSlider
    /// </summary>
    public class SubPowerSliderDrawer : SubDrawer
    {
        public SubPowerSliderDrawer(string group) : this(group, 1) { }
        public SubPowerSliderDrawer(string group, float power)
        {
            this.group = group;
            this.power = Mathf.Clamp(power, 0, float.MaxValue);
        }
        protected override bool matchPropType => prop.type == MaterialProperty.PropType.Range;
        float power;

        public override void DrawProp(Rect position, MaterialProperty prop, GUIContent label, MaterialEditor editor)
        {
            EditorGUI.showMixedValue = prop.hasMixedValue;
            Func.PowerSlider(prop, power, EditorGUILayout.GetControlRect(), label);
            EditorGUI.showMixedValue = false;
        }
    }

    /// <summary>
    /// 绘制float以更改Render Queue
    /// </summary>
    public class QueueDrawer : MaterialPropertyDrawer
    {
        public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor)
        {
            return 0;
        }

        public override void OnGUI(Rect position, MaterialProperty prop, GUIContent label, MaterialEditor editor)
        {
            EditorGUI.BeginChangeCheck();
            editor.FloatProperty(prop, label.text);
            int queue = (int)prop.floatValue;
            if (EditorGUI.EndChangeCheck())
            {
                queue = Mathf.Clamp(queue, 1000, 5000);
                prop.floatValue = queue;
                foreach (Material m in editor.targets)
                {
                    m.renderQueue = queue;
                }
            }
        }
    }

    /// <summary>
    /// 与本插件共同使用，在不带Drawer的prop上请使用内置Header，否则会错位，
    /// </summary>
    public class TitleDecorator : SubDrawer
    {
        private readonly string header;

        public TitleDecorator(string group, string header)
        {
            this.group = group;
            this.header = header;
        }
        public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor)
        {
            if (needShow)
                return 24f;
            else
                return 0;
        }

        public override void DrawProp(Rect position, MaterialProperty prop, GUIContent label, MaterialEditor editor)
        {
            GUIStyle s = new GUIStyle(EditorStyles.boldLabel);
            s.fontSize += 1;
            var r = EditorGUILayout.GetControlRect(true, 24);
            r.yMin += 5;

            EditorGUI.LabelField(r, new GUIContent(header), s);
        }

    }
}
