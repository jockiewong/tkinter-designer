VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsNotebook"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'选项卡类，用于设置和保持相应的属性和值，并生成对应PYTHON的TKinter代码

Private m_dicTotal As Dictionary       '保存全部的属性，包括默认值
Private m_Base As clsBaseControl       '基础控件类
Private m_TabTitles() As String        '选项卡标题，下1开始，0，实际没用
Private m_Tabs() As Object             '选项卡对象，下标从1开始的，0实际没用
Private m_nTabs As Long                '选项卡数目
Private m_CanbeOutByMainForm As Boolean

'输出PYTHON代码,
'sCmdFunc: 输出参数，事件处理回调代码;
'rel:是否使用相对坐标,
'oop:是否使用面向对象编程
'usettk:是否使用TTK主题扩展
Public Sub toString(ByRef sOut As cStrBuilder, ByRef sCmdFunc As cStrBuilder, rel As Boolean, oop As Boolean, usettk As Boolean)
    m_Base.toString sOut, sCmdFunc, rel, oop, usettk
    CreateTabWidgets sOut, sCmdFunc, rel, oop, usettk
End Sub

Private Sub CreateTabWidgets(ByRef sOut As cStrBuilder, ByRef sCmdFunc As cStrBuilder, rel As Boolean, oop As Boolean, usettk As Boolean)
    
    Dim i As Long, nTabs As Long, s As String
    Dim bTabExisted As Boolean, sCaption As String
    
    nTabs = IIf(m_nTabs > UBound(m_Tabs), m_nTabs, UBound(m_Tabs))
    
    For i = 1 To nTabs  'TAB下标从1开始
        If i > UBound(m_Tabs) Then
            bTabExisted = False
        ElseIf m_Tabs(i) Is Nothing Then
            bTabExisted = False
        Else
            bTabExisted = True
        End If
        
        '优先使用TabStrip设置的选项页标题，如果为空，则使用Frame控件的标题。
        If bTabExisted Then
            If i > m_nTabs Then
                sCaption = m_Tabs(i).Caption
            ElseIf Len(m_TabTitles(i)) = 0 Then
                sCaption = m_Tabs(i).Caption
            ElseIf i <= m_nTabs Then
                sCaption = m_TabTitles(i)
            End If
        ElseIf i <= m_nTabs Then
            sCaption = m_TabTitles(i)
        End If
        If Len(sCaption) = 0 Then sCaption = "Tab" & i
        
        CreateSingleTabWidget sOut, sCmdFunc, rel, oop, usettk, i, bTabExisted, sCaption
    Next
    
End Sub

Private Sub CreateSingleTabWidget(ByRef sOut As cStrBuilder, ByRef sCmdFunc As cStrBuilder, rel As Boolean, oop As Boolean, usettk As Boolean, _
                                        nTabIdx As Long, bUseTabObj As Boolean, sCaption As String)
    Dim s As String
    
    If oop Then
        If bUseTabObj Then
            s = "self." & m_Tabs(nTabIdx).Name
            sOut.Append vbCrLf & Space(8) & s & " = Frame(self." & m_Base.Name & ")"
            m_Tabs(nTabIdx).toString sOut, sCmdFunc, rel, oop, usettk
        Else
            s = "self." & m_Base.Name & "__Tab" & nTabIdx
            sOut.Append vbCrLf & Space(8) & s & " = Frame(self." & m_Base.Name & ")"
            sOut.Append Space(8) & s & "Lbl = Label(" & s & ", text='Please add widgets in code.')"
            sOut.Append Space(8) & s & "Lbl.place(relx=0.1,rely=0.5)"
        End If
        
        sOut.Append Space(8) & "self." & m_Base.Name & ".add(" & s & ", text=" & U(sCaption) & ")"
    Else
        If bUseTabObj Then
            s = m_Tabs(nTabIdx).Name
            sOut.Append vbCrLf & Space(4) & s & " = Frame(" & m_Base.Name & ")"
            m_Tabs(nTabIdx).toString sOut, sCmdFunc, rel, oop, usettk
        Else
            s = m_Base.Name & "__Tab" & nTabIdx
            sOut.Append vbCrLf & Space(4) & s & " = Frame(" & m_Base.Name & ")"
            sOut.Append Space(4) & s & "Lbl = Label(" & s & ", text='Please add widgets in code.')"
            sOut.Append Space(4) & s & "Lbl.place(relx=0.1,rely=0.5)"
        End If
        
        sOut.Append Space(4) & m_Base.Name & ".add(" & s & ", text=" & U(sCaption) & ")"
    End If
    
End Sub


'创建对象后要马上调用这个函数初始化各参数
Public Sub InitConfig(o As Object, parentWidth As Long, parentHeight As Long, dMethods As Dictionary)
    Dim i As Long, oiTabs As ITabs, s As String, sa() As String, idx As Long
    
    m_Base.SetVbWidgetInstance o
    
    m_Base.Name = o.Properties("Name")
    
    Set oiTabs = o.Properties("Tabs").object
    m_nTabs = oiTabs.Count
    
    ReDim m_TabTitles(m_nTabs) As String
    For i = 1 To m_nTabs
        m_TabTitles(i) = oiTabs.Item(i).Caption  'TAB下标从1开始
    Next
    
    '这些是所有的默认值
    m_dicTotal("x") = m_Base.toPixelX(o.Properties("Left"))
    m_dicTotal("y") = m_Base.toPixelY(o.Properties("Top"))
    m_dicTotal("width") = m_Base.toPixelX(o.Properties("Width"))
    m_dicTotal("height") = m_Base.toPixelY(o.Properties("Height"))
    m_dicTotal("relx") = Format(o.Properties("Left") / parentWidth, "0.###")
    m_dicTotal("rely") = Format(o.Properties("Top") / parentHeight, "0.###")
    m_dicTotal("relwidth") = Format(o.Properties("Width") / parentWidth, "0.###")
    m_dicTotal("relheight") = Format(o.Properties("Height") / parentHeight, "0.###")
    m_dicTotal("relief") = "FLAT"
    m_dicTotal("tooltip") = o.Properties("ToolTipText")
    m_dicTotal("takefocus") = IIf(o.Properties("TabStop"), 1, 0)
    m_dicTotal("cursor") = m_Base.GetCursorName(o.Properties("MousePointer"))
    m_dicTotal("bindcommand") = m_Base.GetBindCommandStr(dMethods)
    
    '这些是默认选择的
    m_Base("x") = m_dicTotal("x")
    m_Base("y") = m_dicTotal("y")
    m_Base("width") = m_dicTotal("width")
    m_Base("height") = m_dicTotal("height")
    m_Base("relx") = m_dicTotal("relx")
    m_Base("rely") = m_dicTotal("rely")
    m_Base("relwidth") = m_dicTotal("relwidth")
    m_Base("relheight") = m_dicTotal("relheight")
    If m_dicTotal("tooltip") <> "" Then m_Base("tooltip") = m_dicTotal("tooltip")
    If m_dicTotal("takefocus") = 0 Then m_Base("takefocus") = m_dicTotal("takefocus")
    If m_dicTotal("cursor") <> "" Then m_Base("cursor") = m_dicTotal("cursor")
    If m_dicTotal("bindcommand") <> "" Then m_Base("bindcommand") = m_dicTotal("bindcommand")
    
    '使用控件的tag属性保存一些额外默认要保存的属性，
    '开始字符为：p@，后接属性名，每个属性使用@隔开，属性值可选，如果有值，则使用k=v格式
    s = Trim(o.Properties("Tag"))
    If Len(s) Then
        sa = Split(s, "@")
        If sa(0) = "p" Or sa(0) = "P" Then
            For i = 1 To UBound(sa)
                s = sa(i)
                idx = InStr(2, s, "=")
                If idx > 0 Then '有值
                    m_dicTotal(Left$(s, idx - 1)) = Mid$(s, idx + 1)
                    m_Base(Left$(s, idx - 1)) = m_dicTotal(Left$(s, idx - 1))
                ElseIf Len(s) > 0 And Len(m_dicTotal(s)) > 0 Then '仅有属性，则判断属性是否合法
                    m_Base(s) = m_dicTotal(s)
                End If
            Next
        End If
    End If
End Sub

'增加一个标签页
Public Sub AddTab(oTab As Object, nTabIdx As Long)
    
    If nTabIdx > UBound(m_Tabs) Then
        ReDim Preserve m_Tabs(nTabIdx) As Object
    End If
    
    Set m_Tabs(nTabIdx) = oTab
    
End Sub

'设置属性值的可能值列表
'返回值：0-没有可选值，1-有一个严格限制的可选值列表，2-除提供的可选值列表外，还可以手动输入其他值
'输出：sa()可选值列表数组
Public Function GetAttrValueList(sAttr As String, ByRef sa() As String) As Long
    GetAttrValueList = m_Base.GetAttrValueList(sAttr, sa)
End Function

'判断此控件是否存在对应的属性
Public Function hasAttribute(sAttr As String) As Boolean
    hasAttribute = m_Base.hasAttribute(sAttr)
End Function

'获取此控件对应的当前设定的属性值，没有则返回空串
Public Function GetAttrCurrentValue(sAttr As String) As String
    GetAttrCurrentValue = m_Base.GetAttrCurrentValue(sAttr)
End Function

Public Function Tips(sAttr As String) As String
    Tips = m_Base.Tips(sAttr)
End Function

'将用户选择的配置更新到对象中，参数为使用"|"分割的很多对属性/值对
Public Sub SetConfig(sAttrs As String)
    m_Base.SetConfig sAttrs
End Sub

'修改或增加单个配置项，属性/值由"|"分隔
Public Sub SetSingleConfig(sAttr As String)
    m_Base.SetSingleConfig sAttr
End Sub

'返回一个集合，每个项目三元对"属性名|值|是否默认选择"
'这个函数用于主界面填充属性参数列表框
Public Function Allitems() As Collection
    Dim re As Collection, k As Variant, ks As Collection
    
    Set re = New Collection
    
    '标准参数
    Set ks = m_dicTotal.Keys
    For Each k In ks
        If Len(m_Base(k)) Then
            re.Add k & "|" & m_Base(k) & "|1"
        Else
            re.Add k & "|" & m_dicTotal(k) & "|0"
        End If
    Next
    
    '用户增加的自定义参数（如果有的话）
    Set ks = m_Base.Keys
    For Each k In ks
        If Not m_dicTotal.Exists(k) Then
            re.Add k & "|" & m_Base(k) & "|1"
        End If
    Next
    
    Set Allitems = re
    
End Function

Private Sub Class_Initialize()
    Set m_dicTotal = New Dictionary
    Set m_Base = New clsBaseControl
    m_Base.ctlType = "Notebook"
    m_Base.StyleName = "TNotebook"
    ReDim m_TabTitles(0) As String
    ReDim m_Tabs(0) As Object
    m_CanbeOutByMainForm = True
End Sub

Private Sub Class_Terminate()
    Set m_dicTotal = Nothing
    Set m_Base = Nothing
    Erase m_Tabs
    Erase m_TabTitles
End Sub

Public Property Let Parent(s As String)
    m_Base.Parent = s
End Property

Public Property Get Parent() As String
    Parent = m_Base.Parent
End Property

Public Property Get Name() As String
    Name = m_Base.Name
End Property

'用于改变其默认对应的widget类型，修改widget类型后注意属性列表的合法性
Public Function SetWidgetType(sType As String, sStyleName As String)
    m_Base.ctlType = sType
    m_Base.StyleName = sStyleName
End Function

'确定主处理函数能否调用其toString()来产生代码，默认为True，设置为False说明由其他对象来调用处理
Public Property Get EnableOutByMainForm() As Boolean
    EnableOutByMainForm = m_CanbeOutByMainForm
End Property
Public Property Let EnableOutByMainForm(bEnable As Boolean)
    m_CanbeOutByMainForm = bEnable
End Property

'对象序列化函数
Public Function Serializer(vSer As clsSerialization)
    vSer.Serializer m_Base
End Function

Public Function Deserializer(vSer As clsSerialization)
    vSer.Deserializer m_Base
End Function

Public Property Get Description() As String
    Description = L("l_DescNotebook", "Notebook widget. TTK needed.")
End Property

Public Property Let ScaleMode(nV As Long)
    m_Base.ScaleMode = nV
End Property

'用于模拟比较排序的函数，实际上是判断两个对象的依赖关系
'用本对象和另一个对象比较，逻辑结果为'本对象-另一个对象'
'返回值含义：
'<0：表示本对象需要在另一个对象前输出代码
'=0：表示两者将没有依赖关系，代码前后顺序无影响
'>0：另一个对象要先输出代码。
'整体的逻辑结果类似是重的沉底
Public Function Compare(ByRef Obj As Object) As Long
    If Parent = Obj.Name Then '父控件先输出代码
        Compare = 1
    ElseIf Obj.Parent = Name Then
        Compare = -1
    ElseIf Parent = WTOP And Obj.Parent <> WTOP Then '顶层控件先输出
        Compare = -1
    ElseIf Parent <> WTOP And Obj.Parent = WTOP Then
        Compare = 1
    Else
        Compare = 0
    End If
End Function



