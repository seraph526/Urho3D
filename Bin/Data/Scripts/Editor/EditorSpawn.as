// Urho3D spawn editor

LineEdit@ randomRotationX;
LineEdit@ randomRotationY;
LineEdit@ randomRotationZ;
LineEdit@ randomScaleMinEdit;
LineEdit@ randomScaleMaxEdit;
LineEdit@ NumberSpawnedObjectsEdit;
LineEdit@ spawnRadiusEdit;
LineEdit@ spawnCountEdit;

Window@ spawnWindow;
Vector3 randomRotation=Vector3(0.f,0.f,0.f);
float randomScaleMin=1;
float randomScaleMax=1;
float spawnCount=1;
float spawnRadius=0;
bool useNormal=true;

int numberSpawnedObjects=1;
Array<String> spawnedObjectsNames;

void CreateSpawnEditor()
{
    if (spawnWindow !is null)
        return;

    spawnWindow = ui.LoadLayout(cache.GetResource("XMLFile", "UI/EditorSpawnWindow.xml"));
    ui.root.AddChild(spawnWindow);
    spawnWindow.opacity = uiMaxOpacity;

    int height = Min(ui.root.height - 60, 500);
    spawnWindow.SetSize(300, height);
    CenterDialog(spawnWindow);

    HideSpawnEditor();
    SubscribeToEvent(spawnWindow.GetChild("CloseButton", true), "Released", "HideSpawnEditor");
    randomRotationX=spawnWindow.GetChild("RandomRotation.x", true);
    randomRotationY=spawnWindow.GetChild("RandomRotation.y", true);
    randomRotationZ=spawnWindow.GetChild("RandomRotation.z", true);
    randomRotationX.text=String(randomRotation.x);
    randomRotationY.text=String(randomRotation.y);
    randomRotationZ.text=String(randomRotation.z);
    
    randomScaleMinEdit=spawnWindow.GetChild("RandomScaleMin", true);
    randomScaleMaxEdit=spawnWindow.GetChild("RandomScaleMax", true);
    randomScaleMinEdit.text=String(randomScaleMin);
    randomScaleMaxEdit.text=String(randomScaleMax);
    CheckBox@ useNormalToggle = spawnWindow.GetChild("UseNormal", true);
    useNormalToggle.checked = useNormal;

    NumberSpawnedObjectsEdit=spawnWindow.GetChild("NumberSpawnedObjects", true);
    NumberSpawnedObjectsEdit.text=String(numberSpawnedObjects);
    
    spawnRadiusEdit=spawnWindow.GetChild("SpawnRadius", true);
    spawnCountEdit=spawnWindow.GetChild("SpawnCount", true);
    spawnRadiusEdit.text=String(spawnRadius);
    spawnCountEdit.text=String(spawnCount);
    
    SubscribeToEvent(randomRotationX, "TextChanged", "EditRandomRotation");
    SubscribeToEvent(randomRotationY, "TextChanged", "EditRandomRotation");
    SubscribeToEvent(randomRotationZ, "TextChanged", "EditRandomRotation");
    SubscribeToEvent(randomScaleMinEdit, "TextChanged", "EditRandomScale");
    SubscribeToEvent(randomScaleMaxEdit, "TextChanged", "EditRandomScale");
    SubscribeToEvent(spawnRadiusEdit, "TextChanged", "EditSpawnRadius");
    SubscribeToEvent(spawnCountEdit, "TextChanged", "EditSpawnCount");
    SubscribeToEvent(useNormalToggle, "Toggled", "ToggleUseNormal");
    SubscribeToEvent(NumberSpawnedObjectsEdit, "TextFinished", "UpdateNumberSpawnedObjects");
    SubscribeToEvent(spawnWindow.GetChild("SetSpawnMode", true), "Released", "SetSpawnMode");
    RefreshPickedObjects();
}

bool ShowSpawnEditor()
{
    spawnWindow.visible = true;
    spawnWindow.BringToFront();
    return true;
}

void HideSpawnEditor()
{
    spawnWindow.visible = false;
}


void PickSpawnObject()
{
    @resourcePicker = GetResourcePicker(ShortStringHash("Node"));
    if (resourcePicker is null)
        return;

    String lastPath = resourcePicker.lastPath;
    if (lastPath.empty)
        lastPath = sceneResourcePath;
    CreateFileSelector("Pick " + resourcePicker.typeName, "OK", "Cancel", lastPath, resourcePicker.filters, resourcePicker.lastFilter);
    SubscribeToEvent(uiFileSelector, "FileSelected", "PickSpawnObjectDone");
}


void EditRandomRotation(StringHash eventType, VariantMap& eventData)
{
    LineEdit@ edit = eventData["Element"].GetPtr();
    randomRotation = Vector3(randomRotationX.text.ToFloat(), randomRotationY.text.ToFloat(), randomRotationZ.text.ToFloat());
    UpdateHierarchyItem(editorScene);
}

void EditRandomScale(StringHash eventType, VariantMap& eventData)
{
    LineEdit@ edit = eventData["Element"].GetPtr();
    randomScaleMin = randomScaleMinEdit.text.ToFloat();
    randomScaleMax = randomScaleMaxEdit.text.ToFloat();
    UpdateHierarchyItem(editorScene);
}



void ToggleUseNormal(StringHash eventType, VariantMap& eventData)
{
    useNormal = cast<CheckBox>(eventData["Element"].GetPtr()).checked;
}



void UpdateNumberSpawnedObjects(StringHash eventType, VariantMap& eventData)
{
    LineEdit@ edit = eventData["Element"].GetPtr();
    numberSpawnedObjects=edit.text.ToFloat();
    edit.text=String(numberSpawnedObjects); 
    RefreshPickedObjects();
}

void EditSpawnRadius(StringHash eventType, VariantMap& eventData)
{
    LineEdit@ edit = eventData["Element"].GetPtr();
    spawnRadius=edit.text.ToFloat();
}
void EditSpawnCount(StringHash eventType, VariantMap& eventData)
{
    LineEdit@ edit = eventData["Element"].GetPtr();
    spawnCount=edit.text.ToFloat();
}

void RefreshPickedObjects()
{
    spawnedObjectsNames.Resize(numberSpawnedObjects);
    ListView@ list = spawnWindow.GetChild("SpawnedObjects", true);
    list.RemoveAllItems();

    for (uint i = 0; i < numberSpawnedObjects; ++i)
    {
        UIElement@ parent = CreateAttributeEditorParentWithSeparatedLabel(list, "Object " +(i+1), i, 0, false);
        
        UIElement@ container = UIElement();
        container.SetLayout(LM_HORIZONTAL, 4, IntRect(10, 0, 4, 0));
        container.SetFixedHeight(ATTR_HEIGHT);
        parent.AddChild(container);

        LineEdit@ nameEdit = CreateAttributeLineEdit(container, null, i, 0);
        nameEdit.name = "TextureNameEdit" + String(i);

        Button@ pickButton = CreateResourcePickerButton(container, null, i, 0, "Pick");
        SubscribeToEvent(pickButton, "Released", "PickSpawnedObject");
        nameEdit.text = spawnedObjectsNames[i];

        SubscribeToEvent(nameEdit, "TextFinished", "EditSpawnedObjectName");
    }
}

void EditSpawnedObjectName(StringHash eventType, VariantMap& eventData)
{
    LineEdit@ nameEdit = eventData["Element"].GetPtr();
    int index = nameEdit.vars["Index"].GetUInt();
    String resourceName = nameEdit.text;
    XMLFile@ xml = cache.GetResource("XMLFile", resourceName);
    if(xml !is null)
        spawnedObjectsNames[index]=resourceName;
    else
        spawnedObjectsNames[index]=String("");    
    RefreshPickedObjects();
}

void PickSpawnedObject(StringHash eventType, VariantMap& eventData)
{
    UIElement@ button = eventData["Element"].GetPtr();
    resourcePickIndex = button.vars["Index"].GetUInt();
    CreateFileSelector("Pick spawned object", "Pick", "Cancel", uiNodePath, uiSceneFilters, uiNodeFilter);
    
    SubscribeToEvent(uiFileSelector, "FileSelected", "PickSpawnedObjectNameDone");
}

void PickSpawnedObjectNameDone(StringHash eventType, VariantMap& eventData)
{
    StoreResourcePickerPath();
    CloseFileSelector();

    if (!eventData["OK"].GetBool())
    {
        @resourcePicker = null;
        return;
    }

    String resourceName = GetResourceNameFromFullName(eventData["FileName"].GetString());
    XMLFile@ xml = cache.GetResource("XMLFile", resourceName);
    if(xml !is null)
        spawnedObjectsNames[resourcePickIndex]=resourceName;
    else
        spawnedObjectsNames[resourcePickIndex]=String("");
    @resourcePicker = null;
    RefreshPickedObjects();
}

void SetSpawnMode(StringHash eventType, VariantMap& eventData)
{
    editMode=EDIT_SPAWN;
}

void PlaceObject(Vector3 spawnPosition, Vector3 normal)
{
    Quaternion spawnRotation;
    if(useNormal)spawnRotation=Quaternion(Vector3(0.f,1.f,0.f),normal);
    int number=RandomInt(0,spawnedObjectsNames.length);
    XMLFile@ xml = cache.GetResource("XMLFile", spawnedObjectsNames[number]);
    Node@ spawnedObject =editorScene.InstantiateXML(xml, spawnPosition, spawnRotation);
    if(spawnedObject is null)
    {
        spawnedObjectsNames[number]=spawnedObjectsNames[spawnedObjectsNames.length-1];
        --numberSpawnedObjects;
        RefreshPickedObjects();
        return;
    }
    
    spawnedObject.scale=spawnedObject.scale*Random(randomScaleMin, randomScaleMax);
    spawnedObject.Rotate(Quaternion(Random(-randomRotation.x,randomRotation.x),
    Random(-randomRotation.y,randomRotation.y),Random(-randomRotation.z,randomRotation.z)),false);
    CreateNodeAction action;
    action.Define(spawnedObject);
    SaveEditAction(action);
    SetSceneModified();
}

void SpawnObject()
{
    if(spawnedObjectsNames.length==0) return;
    IntRect view = activeViewport.viewport.rect;
    
    for(int i=0;i<spawnCount;i++)
    {	
        Vector2 norm=Vector2(Random(-1,1),Random(-1,1));
        norm.Normalize();
        norm=norm*(spawnRadius*Random(0,1));
        IntVector2 pos = IntVector2(ui.cursorPosition.x+norm.x,ui.cursorPosition.y+norm.y);
        Ray cameraRay = camera.GetScreenRay(
            float(pos.x - view.left) / view.width,
            float(pos.y - view.top) / view.height);

        if (pickMode < PICK_RIGIDBODIES)
        {
            if (editorScene.octree is null)
                return;
            RayQueryResult result = editorScene.octree.RaycastSingle(cameraRay, RAY_TRIANGLE, camera.farClip,
                pickModeDrawableFlags[pickMode], 0x7fffffff);
            if (result.drawable !is null)
                PlaceObject(result.position, result.normal);
        }
        else
        {
            if (editorScene.physicsWorld is null)
                return;

            // If we are not running the actual physics update, refresh collisions before raycasting
            if (!runUpdate)
                editorScene.physicsWorld.UpdateCollisions();

            PhysicsRaycastResult result = editorScene.physicsWorld.RaycastSingle(cameraRay, camera.farClip);
            if (result.body !is null)
                PlaceObject(result.position, result.normal);
        }
    }
}
